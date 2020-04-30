#!/usr/bin/env bash

FILE=""
VERBOSE=0
UPPERCASED_ENV=0
DRY_RUN=0
PREFIX=""

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
    -d, --dry-run               Outputs the resulting file without replacing the original one
    -v, --verbose               Verbose mode, shows the kept and replaced lines
EOF
exit
}

parse_input() {
    skip_next=0
    while [[ $# -ne 0 ]]; do
        if [[ $skip_next -eq 1 ]]; then
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
    if [[ ! "$FILE" ]]; then
        echo "values.yaml file not provided. Please provide a file using -f parameter"
        exit 1
    fi

    if [[ ! -f "$FILE" ]]; then
        echo "$FILE is not a file"
        exit 2
    fi
}

main() {
    parse_input $@
    validate_input

    tmp_file=`mktemp`
    echo "# Generated with helm replace-values-env" > $tmp_file

    while IFS= read -r line; do
        name=`echo "$line" | cut -d \: -f 1`
        var_name=`echo $name`

        if [[ UPPERCASED_ENV -eq 1 ]]; then
            var_name=`echo $name | tr '[:lower:]' '[:upper:]'`
        fi

        value=${!var_name}

        if [[ "$value" ]]; then
            new_line="$name: \"$value\""
            if [[ VERBOSE -eq 1 ]]; then
                echo "REPLACED => |" "$new_line"
            fi

        else
            new_line="$line"
            if [[ VERBOSE -eq 1 ]]; then
                echo "KEPT     => |" "$new_line"
            fi
        fi
        echo "$new_line" >> $tmp_file
    done < $FILE

    if [[ DRY_RUN -eq 1 ]]; then
        cat $tmp_file
    else
        cp $tmp_file $FILE
    fi

    rm $tmp_file
}

main $@
