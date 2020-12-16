# deployment_signature

Allows the pre-signing of code deployments. This is a very complex code deployment workflow that is inly designed for very specific use cases. It should not be adopted generally unless you have a *very* good reason for doing so.

## Description

This module allows a CI tool to pre-sign a code deployment using a pre-shared secret. When code deployment is then triggered using the `deployment_signature::signed_deployment` plan, the code is downloaded and its signature verified before it is added to file-sync.

The purpose of this workflow is to add another layer of auth between the Git & CI tooling and Puppet Enterprise. It also allows for customer metadata about the deployment to be sent and verified on the other end before Puppet Enterprise makes a decision to deploy the code. This could be used for:

* Verification of which user approved a certain code deployment
* Verification that a code deployment was triggered from within a CI system and not just by a rogue user that has access to the credentials

Usually the above risks would be mitigated using the RBAC of CD4PE or whichever CI/CD tool that you were using. However if the integrity of this RBAC is not trusted (i.e. in a scenario where an admin were to change the settings to allow them to approve their own pull requests, then use this to deploy malicious code) then this tool could be helpful for adding an extra layer that would also need to be compromised.

This tooling is not supported by Puppet or Puppet Professional Services. Use at your own discretion.

## Setup

### What deployment_signature affects

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

### Deployment Workflow

When using this module it it intended to be used with a [custom deployment policy](https://puppet.com/docs/continuous-delivery/4.x/custom_deployment_policy.html#add_custom_deployment_policy) an example policy can be seen in the `deployment_signature::signed_deployment` plan. In order to use this plan, do the following:

1. Create a module in the `site-modules` directory of your controlrepo named `deployments` with an appropriate `plans` directory:

    ```shell
    mkdir -p site-modules/deployments/plans
    ```

1. Copy the contents of the `deployment_signature::generate` function from `lib/puppet/functions/deployment_signature/generate.rb` in this module into a new plan in your new directory with the same name i.e. `site-modules/deployments/lib/puppet/functions/deployments/generate.rb`

1. Rename the function to match the new "deployments" module. i.e.

    ```ruby
    Puppet::Functions.create_function(:'deployment_signature::generate') do
    ```

    Would become:

    ```ruby
    Puppet::Functions.create_function(:'deployments::generate') do
    ```


1. Copy the contents of the `deployment_signature::signed_deployment` plan from `plans/signed_deployment.pp` in this module into a new plan in your new directory with the same name i.e. `site-modules/deployments/plans/signed_deployment.pp`

1. Rename the plan to reflect the fact that it is now in a different module i.e.

    ```puppet
    plan deployment_signature::signed_deployment (
      String            $underlying_policy,
      Hash              $underlying_policy_params,
      String            $signature_registration_target,
      Sensitive[String] $signing_secret = Sensitive('puppetlabs'),
    ) {
      # (...)
    }
    ```

    Would become:

    ```puppet
    plan deployments::signed_deployment (
      String            $underlying_policy,
      Hash              $underlying_policy_params,
      String            $signature_registration_target,
      Sensitive[String] $signing_secret = Sensitive('puppetlabs'),
    ) {
      # (...)
    }
    ```

The new [custom deployment policy](https://puppet.com/docs/continuous-delivery/4.x/custom_deployment_policy.html#add_custom_deployment_policy) will perform the following actions:

1. Gather information from CD4PE to embed in the signature. The details of this information is included in the [CD4PE example repo](https://github.com/puppetlabs/puppetlabs-cd4pe_deployments#build-your-own-policy)
1. Wait for approval if this is a protected environment
1. Generate a deployment signature in [JWT](https://jwt.io/) format using the supplied `$signing_secret` and embedding all CD4PE info
1. Run a task on the `signature_registration_target` to register the signature in advance. This will fail if the signature is invalid or already exists
1. Use the `deployment_signature::r10k_deploy` task to deploy the environment to the staging location
1. Retrieve the signature from the store locally and write it to the `.deployment_signature.json` and `.deployment_signature.jwt` files in the root of the repository. This step will fail if the signatures are inconsistent or non-existent
1. Execute the configured validators which will use custom logic in combination with the contents of the deployment signature to determine if the deployment should proceed. This is done using the `deployment_signature::validate` task
1. Commit the code to file sync and therefore make available using the `deployment_signature::file_sync_commit` task

### Custom Validation

It is possible (and likely, since this is the main purpose of the module) to implement custom validation scrips based on the validated information contained within the deployment signature. During a deployment the signature is validated and the written to the root of the environment directory in the following files:

* `deployment_signature.json`: A JSON representation of the data stored in the signature
* `deployment_signature.jwt`: The raw JWT token

Custom scripts written by the user can interrogate this information and either return `0` if the deployment should proceed or non-zero if it should fail. An example of the required Puppet code is:

```puppet
class { 'deployment_signature':
  signing_secret => Sensitive('hunter2'),
  validators     => [
    '/etc/puppetlabs/puppet/validate.sh',
  ],
}

# Create a validator that always passes
file { '/etc/puppetlabs/puppet/validate.sh':
  ensure  => 'file',
  owner   => 'pe-puppet',
  group   => 'pe-puppet',
  mode    => '0700',
  content => "#!/bin/bash\nexit 0",
}
```

Note that validation scripts are run from the root of the environment meaning that the file is in the current working directory for the script. Here is an example of the JSON file:

```json
{
  "cd4pe_pipeline_id": "18r7oi3efjxe009305l8kbtgb1",
  "module_name": "",
  "control_repo_name": "puppet_controlrepo",
  "branch": "main",
  "commit": "6a86f9fa527d2c4a13bb3c5409b53cc02d1a14ee",
  "node_group_id": "321d7a76-0cc2-42f1-9b6f-c52ec0bbae51",
  "node_group_environment": "production",
  "repo_target_branch": "production",
  "environment_prefix": "",
  "repo_type": "CONTROL_REPO",
  "deployment_domain": "d3",
  "deployment_id": "72",
  "deployment_token": "5s85xpun74839h0iqebr0mtrr2qtt1w888b32",
  "deployment_owner": "demo",
  "approval": {
    "result": {
      "approvalDecision": "APPROVED",
      "approvalDecisionDate": 1606320339920,
      "approverUsername": "root"
    },
    "error": null
  },
  "git_ref_update": {
    "result": {
      "success": true
    },
    "error": null
  }
}
```
