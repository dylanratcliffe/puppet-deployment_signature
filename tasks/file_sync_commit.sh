#!/bin/bash

# Determine paths to certs.
cert="$(/opt/puppetlabs/bin/puppet config print hostcert)"
cacert="$(/opt/puppetlabs/bin/puppet config print localcacert)"
key="$(/opt/puppetlabs/bin/puppet config print hostprivkey)"

# Determine request info
type_header='Content-Type: application/json'
uri="https://$(/opt/puppetlabs/bin/puppet config print server):8140/file-sync/v1/commit"
data=$(cat <<EOT
{
  "message": "${PT_message}",
  "author": {
    "name": "${PT_name}",
    "email": "${PT_email}"
  },
  "repo-id": "${PT_repo_id}",
  "submodule-id": "${PT_submodule_id}"
}
EOT
)

curl --header "$type_header" --cert "$cert" --cacert "$cacert" --key "$key" --request POST "$uri" --data "$data"
