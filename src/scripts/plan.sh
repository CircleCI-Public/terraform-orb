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
readonly module_path="${TF_PARAM_PATH}"
export path=$module_path
if [[ ! -d "$module_path" ]]; then
    echo "Path does not exist: $module_path"
    exit 1
fi
# the following is needed to process backend configs
if [[ -n "${TF_PARAM_BACKEND_CONFIG_FILE}" ]]; then
    for file in $(echo "${TF_PARAM_BACKEND_CONFIG_FILE}" | tr ',' '\n'); do
        if [[ -f "$module_path/$file" ]]; then
            INIT_ARGS="$INIT_ARGS -backend-config=$file"
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

readonly workspace_parameter="${TF_PARAM_WORKSPACE}"
readonly workspace="${TF_WORKSPACE:-$workspace_parameter}"
export workspace
unset TF_WORKSPACE

# shellcheck disable=SC2086
terraform -chdir="$module_path" init -input=false $INIT_ARGS

# Test for saving state locally vs a remote state backend storage
if [[ -n "$workspace_parameter" ]]; then
    echo "[INFO] Provisioning local workspace: $workspace"
    terraform -chdir="$module_path" workspace select "$workspace" || terraform -chdir="$module_path" workspace new "$workspace"
else
    echo "[INFO] Remote State Backend Enabled"
fi

if [[ -n "${TF_PARAM_VAR}" ]]; then
    for var in $(echo "${TF_PARAM_VAR}" | tr ',' '\n'); do
        PLAN_ARGS="$PLAN_ARGS -var $var"
    done
fi
if [[ -n "${TF_PARAM_VAR_FILE}" ]]; then
    for file in $(echo "${TF_PARAM_VAR_FILE}" | tr ',' '\n'); do
        if [[ -f "$module_path/$file" ]]; then
            PLAN_ARGS="$PLAN_ARGS -var-file=$file"
        else
            echo "var file '$file' wasn't found" >&2
            exit 1
        fi
    done
fi
export PLAN_ARGS
# shellcheck disable=SC2086
terraform -chdir="$module_path" plan -input=false -out=plan.out $PLAN_ARGS
