#!/usr/bin/env bash
# Installs vitko for GitHub Actions: checks the checksum (always) and the
# build provenance (when the GitHub CLI is available), caches it in the tool
# cache and adds it to the PATH.
set -euo pipefail

repo="vitko-inc/vitko"
version="${INPUT_VERSION:-latest}"

case "${RUNNER_OS:-$(uname -s)}" in
Linux) os=linux ;;
macOS | Darwin) os=darwin ;;
*) echo "::error::vitko runs on Linux and macOS runners, not ${RUNNER_OS:-unknown}." && exit 1 ;;
esac
case "${RUNNER_ARCH:-$(uname -m)}" in
X64 | x86_64) arch=amd64 ;;
ARM64 | arm64 | aarch64) arch=arm64 ;;
*) echo "::error::Unsupported runner architecture: ${RUNNER_ARCH:-unknown}." && exit 1 ;;
esac

api() {
	curl -fsSL --retry 3 -H "Accept: application/vnd.github+json" ${GH_TOKEN:+-H "Authorization: Bearer $GH_TOKEN"} "https://api.github.com/$1"
}

if [ "$version" = "latest" ]; then
	version=$(api "repos/$repo/releases/latest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
fi
case "$version" in v*) ;; *) version="v$version" ;; esac

cache="${RUNNER_TOOL_CACHE:-$HOME/.cache}/vitko/${version#v}/$arch"
if [ ! -x "$cache/vitko" ]; then
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT
	archive="vitko_${os}_${arch}.tar.gz"
	url="https://github.com/$repo/releases/download/$version"
	curl -fsSL --retry 3 -o "$tmp/$archive" "$url/$archive"
	curl -fsSL --retry 3 -o "$tmp/checksums.txt" "$url/checksums.txt"
	want=$(awk -v f="$archive" '$2 == f { print $1 }' "$tmp/checksums.txt")
	if command -v sha256sum >/dev/null; then got=$(sha256sum "$tmp/$archive" | cut -d' ' -f1); else got=$(shasum -a 256 "$tmp/$archive" | cut -d' ' -f1); fi
	if [ -z "$want" ] || [ "$want" != "$got" ]; then
		echo "::error::Checksum mismatch for $archive ($version). Not installing."
		exit 1
	fi
	if [ "${INPUT_VERIFY_PROVENANCE:-true}" = "true" ]; then
		if command -v gh >/dev/null; then
			gh attestation verify "$tmp/$archive" --repo "$repo" >/dev/null
			echo "Build provenance verified."
		else
			echo "::warning::The GitHub CLI isn't installed on this runner, so build provenance wasn't checked (the checksum was)."
		fi
	fi
	mkdir -p "$cache"
	tar -xzf "$tmp/$archive" -C "$cache" vitko
	chmod 0755 "$cache/vitko"
fi

echo "$cache" >>"$GITHUB_PATH"
echo "version=$version" >>"$GITHUB_OUTPUT"
echo "path=$cache/vitko" >>"$GITHUB_OUTPUT"
"$cache/vitko" version --output text
