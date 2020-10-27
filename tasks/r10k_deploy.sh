#!/bin/bash

sudo -u pe-puppet -H bash -c "/opt/puppetlabs/puppet/bin/r10k deploy environment -c /opt/puppetlabs/server/data/code-manager/r10k.yaml -p -v debug $PT_environment"
