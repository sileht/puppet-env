#!/bin/bash
# ssh sileht@gizmo -p 5555 cat /data/puppet/bootstrap.sh | sh

set -e

for p in git puppet hiera hiera-eyaml; do
    dpkg -l $p >/dev/null || apt-get install -y $p
done

#git clone --recursive ssh://sileht@ester.sileht.net:5555/data/puppet /puppet
git clone --recursive https://github.com/sileht/puppet-env.git /puppet

mkdir -p /puppet/keys
scp -P5555 sileht@gizmo.sileht.net:/data/puppet/keys/public_key.pkcs7.pem /puppet/keys/
scp -P5555 sileht@gizmo.sileht.net:/data/puppet/keys/private_key.pkcs7.pem /puppet/keys/

