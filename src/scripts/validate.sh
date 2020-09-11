export path=$TF_PARAM_PATH
if [[ ! -d "$TF_PARAM_PATH" ]]; then
    echo "Path does not exist: \"$TF_PARAM_PATH\""
    exit 1
fi
terraform init -input=false -backend=false -no-color "$TF_PARAM_PATH"
terraform validate -no-color "$TF_PARAM_PATH"