#!/bin/bash
mkdir -p /tmp/terraform-install
cd /tmp/terraform-install || return
wget -P /tmp "https://releases.hashicorp.com/terraform/${TF_PARAM_VERSION}/terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip"
wget -nv "https://releases.hashicorp.com/terraform/${TF_PARAM_VERSION}/terraform_${TF_PARAM_VERSION}_SHA256SUMS"

# Validate checksum
# shellcheck disable=SC2002
expected_sha=$(cat "terraform_${TF_PARAM_VERSION}_SHA256SUMS" | grep "terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" | awk '{print $1}')
download_sha=$(checksumCommand "/tmp/terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip")
echo "Validating download..."
if [ "$expected_sha" != "$download_sha" ]; then
	echo "Expected SHA256SUM does not match downloaded file, exiting."
	exit 1
fi

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
unzip -o "/tmp/terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" -d /tmp
$SUDO mv /tmp/terraform /usr/local/bin
terraform version

# Reported in #61 that recent versions of the Terraform Docker image do not contain shasum
# This is a backwards compatible fix for verifying the Terraform binary
checksumCommand() {
	if [ "$(command -v shasum)" ]; then
		shasum -a 256 "$1" | cut -d' ' -f1
	elif [ "$(command -v sha256sum)" ]; then
		sha256sum "$1" | cut -d' ' -f1
	else
		echo "No checksum tools found."
		exit 1
	fi
}