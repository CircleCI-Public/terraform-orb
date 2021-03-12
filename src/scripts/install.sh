if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
if [[ $TF_PARAM_VERSION == "latest" ]]; then
  echo "Fetching latest version number"
  TF_PARAM_VERSION=$(curl -Ls -w '%{url_effective}' --retry 3 --fail "https://releases.hashicorp.com/terraform/" | grep -m1 -Eo 'terraform_[0-9]+.[0-9]+.[0-9]+<' | grep -m1 -Eo '[0-9]+.[0-9]+.[0-9]+')
  echo "Latest version of Terraform is $TF_PARAM_VERSION"
fi

# Fetch binary
TF_INSTALL_FILE="TF-${TF_PARAM_PLATFORM}.zip"
echo "Downloading Terraform v$TF_PARAM_VERSION for ${TF_PARAM_PLATFORM}"
curl --output "$TF_INSTALL_FILE" \
--silent --show-error --location --fail --retry 3 \
"https://releases.hashicorp.com/terraform/${TF_PARAM_VERSION}/terraform_${TF_PARAM_VERSION}_${TF_PARAM_PLATFORM}.zip"
echo "Installing"
unzip "$TF_INSTALL_FILE"
$SUDO mv terraform /usr/local/bin
terraform version