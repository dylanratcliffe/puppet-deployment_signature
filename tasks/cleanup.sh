#!/bin/bash
set -x
exec 2>&1

sudo -u pe-puppet -H bash -c "rm -rf $PT_code_staging/environments/$PT_environment/{*,.*}"
rm -f $PT_signature_location/$PT_environment/$PT_commit_hash.jwt
