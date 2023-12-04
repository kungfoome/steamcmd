#!/bin/bash
 
GITHUB_REPO="gorcon/rcon-cli"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}"
printf "RCON: %s\n\n"  ${RCON_VERSON}
if [ "${RCON_VERSION}" == "latest" ]; then
    printf "Fetching latest RCON version\n"
    RCON_VERSION=$(curl -s "${GITHUB_API}/releases/latest" | jq -r .tag_name)
    printf "Found RCON version: %s\n" "${RCON_VERSON}"
fi

GITHUB_DOWNLOAD_URL=$(curl -s "${GITHUB_API}/releases/tags/${RCON_VERSION}" | grep browser_download_url | grep -wo  https.*.amd64_linux.tar.gz )

if [ "${GITHUB_DOWNLOAD_URL}" == "" ]; then
    printf "Could not find download url for RCON version: '%s'\n" "${RCON_VERSION}"
    exit 1
fi

printf "Downloading RCON (%s) from %s\n" "${RCON_VERSION}" "${GITHUB_DOWNLOAD_URL}"

curl -sL "${GITHUB_DOWNLOAD_URL}" | tar zx

mv rcon* rcon
