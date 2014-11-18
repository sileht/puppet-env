#!/bin/bash

here=$(readlink -f $(dirname $0))

cd $here
rm -f check-mk-agent_*.deb
filepath=$(ssh -p 2222 nagios.t ls /omd/sites/ttnn/share/check_mk/agents/check-mk-agent_* | sort -Vr | head -1)
file=$(basename $filepath)
scp -P2222 nagios.t:$filepath $file
git add $file


sed -i -e "/checkmk::agent::package/s,.*,checkmk::agent::package: /puppet/files/$file," ../checkmk.yaml
