#!/usr/bin/env sh

FILE=""
VERBOSE=0
UPPERCASED_ENV=0
DRY_RUN=0
PREFIX=""
IGNORED=""

help() {
cat << EOF
Replaces values on a given 'values.yaml' file with the values from environment
variables with the same name.

Usage:
    helm replace-values-env [OPTIONS]

Options:
    -h, --help                  Shows usage help
    -f values.yaml              The file to have it's values replaced
    -p, --prefix <prefix>       A prefix to be removed from the variables' names
    -u, --uppercased            The environment variables are in uppercase
    -i, --ignore <var1,var2>    Comma separated list of variables to ignore
    -d, --dry-run               Outputs the resulting file without replacing the original one
    -v, --verbose               Verbose mode, shows the kept and replaced lines
EOF
exit
}

parse_input() {
    skip_next=0
    while [ $# -ne 0 ]; do
        if [ $skip_next -eq 1 ]; then
            shift
            skip_next=0
        fi

        case "$1" in
            -h | --help)
                help
                exit
                ;;
            -f)
                FILE="$2"
                skip_next=1
                ;;
            -p | --prefix)
                PREFIX="$2"
                skip_next=1
                ;;
            -u | --uppercased)
                UPPERCASED_ENV=1
                ;;
            -i | --ignore)
                IGNORED="$2"
                skip_next=1
                ;;
            -d | --dry-run)
                DRY_RUN=1
                ;;
            -v | --verbose)
                VERBOSE=1
                ;;
        esac

        shift
    done
}

validate_input() {
    if [ ! "$FILE" ]; then
        echo "values.yaml file not provided. Please provide a file using -f parameter"
        exit 1
    fi

    if [ ! -f "$FILE" ]; then
        echo "$FILE is not a file"
        exit 2
    fi
}

trim() {
    echo "$1" | sed -e 's/^[ \t]*//'
}

parse_var_name() {
    var_name="$1"

    if [ $UPPERCASED_ENV -eq 1 ]; then
        var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
    fi

    var_name=$(trim "$var_name")

    if [ "$PREFIX" ]; then
        var_name="$PREFIX$var_name"
    fi

    echo "$var_name"
}

is_comment() {
    line=$(trim "$1")
    first=$(echo "$line" | cut -c1-1)

    if [ "#" = "$first" ]; then
        echo "1"
    else
        echo ""
    fi
}

is_list_item() {
    line=$(trim "$1")
    first=$(echo "$line" | cut -c1-1)

    if [ "-" = "$first" ]; then
        echo "1"
    else
        echo ""
    fi
}

is_ignored() {
    b=$IFS
    IFS=","
    for var_name in $IGNORED
    do
        if [ "$var_name" = "$1" ]; then
            echo "1"
        fi
    done
    IFS=$b

    echo ""
}

main() {
    parse_input "$@"
    validate_input

    tmp_file=$(mktemp)
    echo "# Generated with helm replace-values-env" > "$tmp_file"

    while IFS= read -r line; do
        is_line_a_comment=$(is_comment "$line")
        is_line_a_list_item=$(is_list_item "$line")

        if [ "$is_line_a_comment" ] || [ "$is_line_a_list_item" ]; then
            if [ $VERBOSE -eq 1 ]; then
                echo "KEPT     => |" "$line"
            fi

            echo "$line" >> "$tmp_file"

            continue
        fi

        name=$(echo "$line" | cut -d \: -f 1)
        var_name=$(parse_var_name "$name")

        if [ ! "$var_name" ]; then
            continue
        fi

        is_var_name_ignored=$(is_ignored "$var_name")

        if [ "$is_var_name_ignored" ]; then
            if [ $VERBOSE -eq 1 ]; then
                echo "IGNORED  => |" "$line"
            fi

            echo "$line" >> "$tmp_file"

            continue
        fi

        value=$(eval "echo \$$var_name")

        if [ "$value" ]; then
            new_line="$name: \"$value\""
            if [ $VERBOSE -eq 1 ]; then
                echo "REPLACED => |" "$new_line"
            fi

        else
            new_line="$line"
            if [ $VERBOSE -eq 1 ]; then
                echo "KEPT     => |" "$new_line"
            fi
        fi
        echo "$new_line" >> "$tmp_file"
    done < "$FILE"

    if [ $DRY_RUN -eq 1 ]; then
        cat "$tmp_file"
    else
        cp "$tmp_file" "$FILE"
    fi

    rm "$tmp_file"
}

main "$@"
