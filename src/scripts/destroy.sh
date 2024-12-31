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
export INIT_ARGS
# shellcheck disable=SC2086
terraform -chdir="$module_path" init -input=false $INIT_ARGS

# Set workspace from parameter, allowing it to be overridden by TF_WORKSPACE.

# If TF_WORKSPACE is set we don't want terraform init to use the value, in the case we are running new_workspace.sh this would cause an error

workspace_parameter="$(eval echo "${TF_PARAM_WORKSPACE}")"

readonly workspace="${TF_WORKSPACE:-$workspace_parameter}"

export workspace

unset TF_WORKSPACE

rm -rf .terraform
# The line below is the original place for the init
# terraform -chdir="$module_path" init -input=false -lock-timeout=300s $INIT_ARGS

# Test for saving state locally vs a remote state backend storage
if [[ -n "$workspace_parameter" ]]; then
    echo "[INFO] Provisioning local workspace: $workspace"
    terraform -chdir="$module_path" workspace select "$workspace"
else
    echo "[INFO] Remote State Backend Enabled"
fi
if [[ -n "${TF_PARAM_VAR}" ]]; then
    re='([^,=]+)=\[([A-Za-z0-9,]*)*\]|([^,=]+)=[^,]*'
    PLAN_ARGS=""
    while [[ $TF_PARAM_VAR =~ $re ]]; do
        match="${BASH_REMATCH[0]}"
        PLAN_ARGS="$PLAN_ARGS -var $match"
        TF_PARAM_VAR="${TF_PARAM_VAR#"$match"}"
        TF_PARAM_VAR="${TF_PARAM_VAR#,}"
    done
    echo "$PLAN_ARGS"
fi

if [[ -n "${TF_PARAM_VAR_FILE}" ]]; then
    for file in $(eval echo "${TF_PARAM_VAR_FILE}" | tr ',' '\n'); do
        if [[ -f "$module_path/$file" ]] || [[ -f "$file" ]]; then
            PLAN_ARGS="$PLAN_ARGS -var-file=$file"
        else
            echo "Var file '$file' wasn't found" >&2
            exit 1
        fi
    done
fi

export PLAN_ARGS
# terraform -chdir="$module_path" init -input=false -lock-timeout=300s $INIT_ARGS
# shellcheck disable=SC2086
terraform -chdir="$module_path" apply -destroy -input=false -auto-approve $PLAN_ARGS
