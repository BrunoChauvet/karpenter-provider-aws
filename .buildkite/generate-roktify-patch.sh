#!/usr/bin/env bash

# Script relies on configured upstream remote
BASE_VERSION="v1.3.3"
TMP_PATCH=$(mktemp)

git fetch upstream --tags
rm -fv roktify.patch
git diff --binary --unified=3 "${BASE_VERSION}" > "${TMP_PATCH}"
mv -fv "${TMP_PATCH}" ./roktify.patch
