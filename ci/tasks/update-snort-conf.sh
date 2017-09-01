#!/bin/bash

set -eox pipefail
IFS=$'\n\t'

cd pulledpork-output

cat << EOF > config/private.yml
---
blobstore:
  provider: s3
  options:
    access_key_id: $S3_ACCESS_KEY_ID
    secret_access_key: $S3_SECRET_ACCESS_KEY
EOF

cp -rf ../snort-boshrelease-git/. ../snort-boshrelease-git-modified

bosh -n sync-blobs
SNORT_RULES_SHA1=$(cat ci/config/snort-conf/rules/snort.rules | sha1sum)
if [ "${FORCE_UPDATE}" -eq "1" ] || [ "${SNORT_RULES_SHA1}" != "$(tar -xOf blobs/snort-conf.tar.gz snort-conf/rules/snort.rules | sha1sum)" ] ; then

  echo "Updating snort-conf"

  # create new snort-conf.tar.gz
  tar czvf snort-conf.tar.gz -C ci/config snort-conf

  bosh -n add-blob snort-conf.tar.gz snort-conf.tar.gz
  bosh -n upload-blobs

  cp config/blobs.yml ../snort-boshrelease-git-modified/config
  cd ../snort-boshrelease-git-modified

  if [[ -z $(git config --global user.email) ]]; then
    git config --global user.email "${GITHUB_USERNAME}@users.noreply.github.com"
  fi
  if [[ -z $(git config --global user.name) ]]; then
    git config --global user.name "${GITHUB_USERNAME}"
  fi

  git commit config/blobs.yml -m"Update rules

snort.rules SHA1: ${SNORT_RULES_SHA1}"
else
  echo "Not updating snort-conf - snort rules have not changed"
fi
