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
readonly module_path="$(eval echo "$TF_PARAM_PATH")"
export path=$module_path
if [[ ! -d "$module_path" ]]; then
    echo "Path does not exist: $module_path"
    exit 1
fi

workspace_parameter="$(eval echo "${TF_PARAM_WORKSPACE}")"
readonly workspace="${TF_WORKSPACE:-$workspace_parameter}"
export workspace
unset TF_WORKSPACE

terraform -chdir="$TF_PARAM_PATH" init -input=false -backend=false

if [[ -n "$workspace_parameter" ]]; then
    echo "[INFO] Provisioning local workspace: $workspace"
    terraform -chdir="${TF_PARAM_PATH}" workspace select "$workspace" || terraform -chdir="${TF_PARAM_PATH}" workspace new "$workspace"
else
    echo "[INFO] Remote State Backend Enabled"
fi

terraform -chdir="$TF_PARAM_PATH" validate
