# Helm Replace Values With Environment Variables

Replaces values in a given `values.yaml` file with the values from environment
variables.

## Scenario

A HELM chart has a `values.yaml` file that contains the values to be replaced
inside the templates.

It is quite normal to store secrets and other configuration variables on tools
for CI/CD and then to override the values in `values.yaml` using the values from
such variables using the option `--set-string` from helm install.

This is easy to be done but can generate huge `helm install` commands with tens
of lines with `--set-string`.

Instead of using `--set-string` one can replace the values from `values.yaml`
with the values from the environment variables that are already on the CI/CD
runner.

### Example

Let's say you have the following `values.yaml` contents:

```yaml
payment_service_url: "https://payment-service-dev.com"
session_service_url: "https://session-service-dev.com"
```

And on your CI/CD runner you have the variables:

```sh
export PAYMENT_SERVICE_URL="https://payment-service-production.com"
export SESSION_SERVICE_URL="https://session-service-production.com"
```

You can replace the values with this plugin using the following command:

```sh
helm replace-values-env -f values.yaml -u
```

The `-u` option will tell the plugin the environment variables are in uppercase.

The resulting file would be:

```yaml
payment_service_url: "https://payment-service-production.com"
session_service_url: "https://session-service-production.com"
```

## Usage

```
Usage:
    helm replace-values-env [OPTIONS]

Options:
    -h, --help                  Shows usage help
    -f <file>                   The file to have it's values replaced
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
