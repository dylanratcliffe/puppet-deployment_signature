#!/bin/bash
set -x

sudo -u pe-puppet -H bash -c "rm -rf $PT_code_staging/$PT_environment"
rm -f $PT_signature_location/$PT_environment/$PT_commit_hash.jwt