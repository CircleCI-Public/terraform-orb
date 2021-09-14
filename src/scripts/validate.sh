TF_PARAM_PATH=$(eval echo "\$$TF_PARAM_PATH")

export path=$TF_PARAM_PATH
if [[ ! -d "$TF_PARAM_PATH" ]]; then
    echo "Path does not exist: $TF_PARAM_PATH"
    exit 1
fi
terraform -chdir="$TF_PARAM_PATH" init -input=false -backend=false -no-color
terraform -chdir="$TF_PARAM_PATH" validate -no-color