#!/bin/bash
# Check CLI config file
if [[ -n "${TF_PARAM_CLI_CONFIG_FILE}" ]]; then
    if [[ -f "${TF_PARAM_CLI_CONFIG_FILE}" ]]; then
        export TF_CLI_CONFIG_FILE=${TF_PARAM_CLI_CONFIG_FILE}
    else
        echo "Terraform cli config does not exist: \"${TF_PARAM_CLI_CONFIG_FILE}\""
        exit 1
    fi
fi
# 'path' is a required parameter, save it as module_path
readonly module_path="${TF_PARAM_PATH}"
export path=$module_path

export backend="${TF_PARAM_BACKEND}"

if [[ ! -d "$module_path" ]]; then
  echo "Path does not exist: \"$module_path\""
  exit 1
fi

# Initialize terraform
if [[ -n "${TF_PARAM_BACKEND_CONFIG_FILE}" ]]; then
    for file in $(echo "${TF_PARAM_BACKEND_CONFIG_FILE}" | tr ',' '\n'); do
        if [[ -f "$file" ]]; then
            INIT_ARGS="$INIT_ARGS -backend-config=$file"
        elif [[ -f "$module_path/$file" ]]; then
            INIT_ARGS="$INIT_ARGS -backend-config=$module_path/$file"
        else
            echo "Backend config '$file' wasn't found" >&2
            exit 1
        fi
    done
fi
if [[ -n "${TF_PARAM_BACKEND_CONFIG}" ]]; then
    for config in $(echo "${TF_PARAM_BACKEND_CONFIG}" | tr ',' '\n'); do
        INIT_ARGS="$INIT_ARGS -backend-config=$config"
    done
fi
export INIT_ARGS
terraform -chdir="$module_path" init -input=false -no-color -backend=$backend $INIT_ARGS
