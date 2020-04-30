# Helm Replace Values Env

Replaces values in a given `values.yaml` file with the values from environment
variables.

## Usage

```
Usage:
    helm replace-values-env [OPTIONS]

Options:
    -h, --help                  Shows usage help
    -f values.yaml              The file to have it's values replaced
    -p, --prefix <prefix>       A prefix to be removed from the variables' names
    -u, --uppercased            The environment variables are in uppercase
    -d, --dry-run               Outputs the resulting file without replacing the original one
    -v, --verbose               Verbose mode, shows the kept and replaced lines
```

## Install

```
$ helm plugin install https://github.com/infog/helm-replace-values-env
Installed plugin: replace-values-env
```
