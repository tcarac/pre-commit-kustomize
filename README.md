# pre-commit-kustomize
pre-commit hook which runs kustomize and kubeconform. It requires both executables to be available in path.

## Example of .pre-commit-config.yaml that verifies kustomize files in a monorepo
```yaml
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v2.4.0
    hooks:
    -   id: check-yaml
        args: [--allow-multiple-documents]
    -   id: check-added-large-files
-   repo: https://github.com/tcarac/pre-commit-kustomize
    rev: v0.1.0
    hooks:
    -   id: kustomize
```
## Example of usage in github actions
```yaml
name: pre-commit

on:
  pull_request:
  push:
    branches: [main]

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - uses: actions/setup-python@v3
    - uses: yokawasa/action-setup-kube-tools@v0.11.1
      with:
        kubectl: 1.30.0
        kustomize: 5.4.1
        kubeconform: 0.6.6
    - uses: pre-commit/action@v3.0.1
      with:
        extra_args: kustomize --all-files

```