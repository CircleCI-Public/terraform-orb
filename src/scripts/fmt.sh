#!/bin/bash

# 'path' is a required parameter, save it as module_path
readonly module_path="$TF_PARAM_MOD_PATH"
export path=$module_path

if [[ ! -d "$module_path" ]]; then
  echo "Path does not exist: \"$module_path\""
  exit 1
fi
if [ "$TF_PARAM_IS_RECURSIVE" = "1" ]; then
 set -- "$@" -recursive
fi
terraform -chdir="$module_path" fmt -no-color -check -diff "$@"