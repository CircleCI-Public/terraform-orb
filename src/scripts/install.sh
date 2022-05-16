#!/bin/bash

set -euo pipefail

download_version() {
	version=$1
	local base_url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}"
	wget -nv "${base_url}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip"
	wget -nv "${base_url}_SHA256SUMS"
}

init() {
	mkdir -p /tmp/terraform-install
	cd /tmp/terraform-install
}

# Reported in #61 that recent versions of the Terraform Docker image do not contain shasum
# This is a backwards compatible fix for verifying the Terraform binary
checksumCommand() {
	file=$1
	if [ "$(command -v shasum)" ]; then
		shasum -a 256 "$file" | cut -d' ' -f1
	elif [ "$(command -v sha256sum)" ]; then
		sha256sum "$file" | cut -d' ' -f1
	else
		echo "No checksum tools found."
		exit 1
	fi
}

checksum_package() {
	# Validate checksum
	# shellcheck disable=SC2002
	expected_sha=$(cat "terraform_${TF_PARAM_VERSION}_SHA256SUMS" | grep "terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" | awk '{print $1}')
	export -f checksumCommand
	download_sha=$(checksumCommand "terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip")
	echo "Validating download..."
	if [ "$expected_sha" != "$download_sha" ]; then
		echo "Expected SHA256SUM does not match downloaded file, exiting."
		exit 1
	fi
}

install_terraform() {
	unzip -o "terraform_${TF_PARAM_VERSION}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip"
	if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
	$SUDO mv terraform /usr/local/bin
}

init
download_version "${TF_PARAM_VERSION}"
checksum_package
install_terraform
terraform version
