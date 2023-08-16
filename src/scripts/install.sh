#!/bin/bash
set -x
download_version() {
	version=$1
	local base_url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}"
	wget -nv "${base_url}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip"
	wget -nv "${base_url}_SHA256SUMS"
}

init() {
	mkdir -p /tmp/terraform-install
	cd /tmp/terraform-install || exit 1
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
	version=$1
	# shellcheck disable=SC2002
	expected_sha=$(cat "terraform_${version}_SHA256SUMS" | grep "terraform_${version}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip" | awk '{print $1}')
	export -f checksumCommand
	download_sha=$(checksumCommand "terraform_${version}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip")
	echo "Validating download..."
	if [ "$expected_sha" != "$download_sha" ]; then
		echo "Expected SHA256SUM does not match downloaded file, exiting."
		exit 1
	fi
}

install_terraform() {
	version=$1
	unzip -o "terraform_${version}_${TF_PARAM_OS}_${TF_PARAM_ARCH}.zip"
	if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
	$SUDO mv terraform /usr/local/bin
}

determine_version() {
	# We might have an exact version, a partial version, or "latest"
	version_spec=$1

	version_regex="^[0-9]+\.[0-9]+\.[0-9]+$"

	# Exact version needs no further processing
	if [[ $version_spec =~ $version_regex ]]; then
		echo "$version_spec"
		return
	fi

	index_json=$(curl -sf https://releases.hashicorp.com/terraform/index.json)
	released_versions=$(echo "$index_json" | jq -r '.versions | keys | .[]' | grep -E "$version_regex" | sort -rV)

	if [[ $version_spec = latest ]]; then
		head -1 <<< "$released_versions"
		return
	fi

	grep -m1 -E "^$version_spec" <<< "$released_versions" || {
		echo "Couldn't find matching version for '$version_spec'"
		exit 1
	}
	return
}

init
tf_version=$(determine_version "$TF_PARAM_VERSION")
echo "Using Terraform version '$tf_version'"
download_version "${tf_version}"
checksum_package "${tf_version}"
install_terraform "${tf_version}"
terraform version
