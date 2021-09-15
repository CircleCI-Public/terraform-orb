#!/bin/bash
# Check CLI config file
if [[ -n "${TF_PARAM_CLI_CONFIG_FILE}" ]]; then
    if [[ -f "${TF_PARAM_CLI_CONFIG_FILE}" ]]; then
        export TF_CLI_CONFIG_FILE=${TF_PARAM_CLI_CONFIG_FILE}
    else
        echo "Terraform cli config does not exist: ${TF_PARAM_CLI_CONFIG_FILE}"
        exit 1
    fi
fi
export path=$TF_PARAM_PATH
if [[ ! -d "$TF_PARAM_PATH" ]]; then
    echo "Path does not exist: $TF_PARAM_PATH"
    exit 1
fi
terraform -chdir="$TF_PARAM_PATH" init -input=false -backend=false -no-color
terraform -chdir="$TF_PARAM_PATH" validate -no-color