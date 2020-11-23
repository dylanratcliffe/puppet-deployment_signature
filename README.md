# deployment_signature

Allows the pre-signing of code deployments. This is a very complex code deploment workflow that is inly designed for very specific use cases. It should not be adopted generally unless you have a *very* good reason for doing so.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with deployment_signature](#setup)
    * [What deployment_signature affects](#what-deployment_signature-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with deployment_signature](#beginning-with-deployment_signature)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module allows a CI tool to pre-sign a code deployment using a pre-shared secret. When code deployment is then triggered using the `deployment_signature::signed_deployment` plan, the code is downloaded and its signature verified before it is added to file-sync.

The purpose of this workflow is to add another layer of auth between the Git & CI tooling and Puppet Enterprise. It also allows for customer metadata about the deployment to be sent and verified on the other end before Puppet Enterprise makes a decision to deploy the code. This could be used for:

* Verification of which user approved a certain code deployment
* Verification that a code deployment was triggered from within a CI system and not just by a rogue user that has access to the credentials

Usually the above risks would be mitigated using the RBAC of CD4PE or whichever CI/CD tool that you were using. However if the integrity of this RBAC is not trusted (i.e. in a scenario where an admin were to change the settings to allow them to approve their own pull requests, then use this to deploy malicious code) then this tool could be helpful for adding an extra layer that would also need to be compromised.

This tooling is not supported by Puppet or Puppet Professional Services. Use at your own discretion.

## Setup

### What deployment_signature affects **OPTIONAL**

The `deployment_signature` module configures following things on the Puppet server:

* `/etc/puppetlabs/puppet/deployment_signatures.yaml`: Contains configuration used to verify deployment signatures
* `/etc/puppetlabs/puppet/deployment_signatures`: Folder containing registered deployment signatures
* `jwt`: Gem installed using the `puppet_gem` provider

The above configuration enables the use of the tasks and plans in this module.

## Usage

### Basic Configuration

Add the following to the classification for your primary puppet server:

```puppet
class { 'deployment_signature':
  signing_secret => Sensitive('something_secret'),
}
```