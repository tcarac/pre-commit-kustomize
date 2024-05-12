#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

validate_kustomization() {
    dir=$1
    echo -e "${NC}Validating kustomization in directory: ${dir}${NC}"

    build_output=$(kustomize build "$dir" 2>&1)
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo -e "${RED}Kustomize build failed for directory: ${dir}${NC}\n${build_output}"
        return 1
    fi

    validation_output=$(echo "$build_output" | kubeconform -schema-location default \
        -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' 2>&1)
    validation_status=$?

    if [ $validation_status -ne 0 ]; then
        echo -e "${RED}Validation failed for directory: ${dir}${NC}\n${validation_output}"
        return 1
    else
        echo -e "${GREEN}Validation successful for directory: ${dir}${NC}"
    fi
}

find_nearest_kustomization() {
    path=$1
    while [ "$path" != "" ] && [ ! -e "$path/kustomization.yaml" ]; do
        path=${path%/*}
    done
    echo "$path"
}

all_valid=true
for file in "$@"; do
    if [ -f "$file" ]; then
        dir=$(dirname "$file")
        kustomization_dir=$(find_nearest_kustomization "$dir")
        if [ -n "$kustomization_dir" ]; then
            if ! validate_kustomization "$kustomization_dir"; then
                all_valid=false
            fi
        else
            echo -e "${RED}No kustomization.yaml found for file $file${NC}"
            all_valid=false
        fi
    fi
done

if $all_valid; then
    echo -e "${GREEN}All kustomization validations successful!${NC}"
else
    exit 1
fi
