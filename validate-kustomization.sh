#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

validate_kustomization() {
    dir=$1
    echo -e "${NC}Validating kustomization in directory: ${dir}${NC}"

    build_output=$(kustomize build "$dir" 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Kustomize build failed for directory: ${dir}${NC}\n${build_output}"
        return 1
    fi

    echo "$build_output" | kubeconform -schema-location default \
        -schema-location 'https://kubernetesjsonschema.dev' \
        -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
        -ignore-missing-schemas
    if [ $? -ne 0 ]; then
        echo -e "${RED}Validation failed for directory: ${dir}${NC}"
        return 1
    else
        echo -e "${GREEN}Validation successful for directory: ${dir}${NC}"
    fi
}

# Function to find and validate all kustomizations in the repository
validate_all_kustomizations() {
    find . -name 'kustomization.yaml' -print0 | while IFS= read -r -d $'\0' file; do
        kustomization_dir=$(dirname "$file")
        validate_kustomization "$kustomization_dir" || exit 1
    done
}

# Check if any filenames were passed to the script
if [ $# -eq 0 ]; then
    # No filenames passed, validate all kustomizations
    validate_all_kustomizations
else
    # Filenames were passed, process each one
    for file in "$@"; do
        if [ -f "$file" ] && [[ "$file" == *.yaml || "$file" == *.yml ]]; then
            kustomization_dir=$(dirname "$file")
            validate_kustomization "$kustomization_dir"
        else
            echo -e "${RED}No kustomization.yaml found for file: $file${NC}"
        fi
    done
fi
