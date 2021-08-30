#!/bin/bash
# 'path' is a required parameter, save it as module_path
readonly module_path="${TF_PARAM_PATH}"
export path=$module_path

export recursive="${TF_PARAM_RECURSIVE}"

if [[ ! -d "$module_path" ]]; then
    echo "Path does not exist: $module_path"
    exit 1
fi

# shellcheck disable=SC2086
terraform -chdir="$module_path" fmt -no-color -check -diff -recursive=$recursive
