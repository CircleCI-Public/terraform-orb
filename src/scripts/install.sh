echo "Terraform Version function: $(eval echo "$TF_PARAM_VERSION")"
echo "Terraform Version: $TF_PARAM_VERSION"

TF_PARAM_VERSION=$(eval echo "\$$TF_PARAM_VERSION")
TF_PARAM_OS=$(eval echo "\$$TF_PARAM_OS")
TF_PARAM_ARCH=$(eval echo "\$$TF_PARAM_ARCH")

mkdir -p /tmp/terraform-install
cd /tmp/terraform-install || return
wget -P /tmp "https://releases.hashicorp.com/terraform/${TF_PARAM_VERSION}/terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip"
wget -nv "https://releases.hashicorp.com/terraform/${TF_PARAM_VERSION}/terraform_${TF_PARAM_VERSION}_SHA256SUMS"

# Validate checksum
# shellcheck disable=SC2002
expected_sha=$(cat "terraform_${TF_PARAM_VERSION}_SHA256SUMS" | grep "terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" | awk '{print $1}')
download_sha=$(shasum -a 256 "/tmp/terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" | cut -d' ' -f1)
echo "Validating download..."
if [ "$expected_sha" != "$download_sha" ]; then
	echo "Expected SHA256SUM does not match downloaded file, exiting."
	exit 1
fi

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
unzip -o "/tmp/terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" -d /tmp
$SUDO mv /tmp/terraform /usr/local/bin
terraform version