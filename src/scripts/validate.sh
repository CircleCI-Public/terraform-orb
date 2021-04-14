export path=$TF_PARAM_PATH
if [[ ! -d "$TF_PARAM_PATH" ]]; then
    echo "Path does not exist: \"$TF_PARAM_PATH\""
    exit 1
fi
terraform  -chdir="$TF_PARAM_PATH" init -input=false -backend=false -no-color
terraform validate -no-color "$TF_PARAM_PATH"
