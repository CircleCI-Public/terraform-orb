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
# 'path' is a required parameter, save it as module_path
module_path="$(eval echo "$TF_PARAM_PATH")"
readonly module_path
path=$module_path
export path


if [[ ! -d "$module_path" ]]; then
    echo "Path does not exist: $module_path"
    exit 1
fi
backend="${TF_PARAM_BACKEND}"
export backend

# Initialize terraform
if [[ -n "${TF_PARAM_BACKEND_CONFIG_FILE}" ]]; then
    for file in $(echo "${TF_PARAM_BACKEND_CONFIG_FILE}" | tr ',' '\n'); do
        if [[ -f "$module_path/$file" ]] || [[ -f "$file" ]]; then
            INIT_ARGS="$INIT_ARGS -backend-config=$file"
        else
            echo "Backend config '$file' wasn't found" >&2
            exit 1
        fi
    done
fi
if [[ -n "${TF_PARAM_BACKEND_CONFIG}" ]]; then
    for config in $(echo "${TF_PARAM_BACKEND_CONFIG}" | tr ',' '\n'); do
        INIT_ARGS="$INIT_ARGS -backend-config=$(eval echo "$config")"
    done
fi

if [[ "${TF_PARAM_UPGRADE}" = true ]]; then
    INIT_ARGS="$INIT_ARGS -upgrade"
fi

export INIT_ARGS
# shellcheck disable=SC2086
terraform -chdir="$module_path" init -input=false -backend=$backend $INIT_ARGS
