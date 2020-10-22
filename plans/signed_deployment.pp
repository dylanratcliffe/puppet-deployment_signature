# This deployment policy will perform a Puppet code deploy of the commit
# associated with a Pipeline run. Puppet nodes that are scheduled to run regularly will then pick up the
# change until all nodes in the target environment are running against the new
# code.
#
# @summary This deployment policy will perform a Puppet code deploy of the commit
#          associated with a Pipeline run. 
#
# @param underlying_policy The deployment policy that this should defer to after the signature has been registered e.g. 
# @param underlying_policy_params 
# @param signature_registration_target 
# @param signing_secret 
plan deployment_signature::signed_deployment (
  String            $underlying_policy,
  Hash              $underlying_policy_params,
  String            $signature_registration_target,
  Sensitive[String] $signing_secret = Sensitive('puppetlabs'),
) {
  # Gather all the data that we possibly can
  $deployment_info = {
    'cd4pe_pipeline_id'      => system::env('CD4PE_PIPELINE_ID'),
    'module_name'            => system::env('MODULE_NAME'),
    'control_repo_name'      => system::env('CONTROL_REPO_NAME'),
    'branch'                 => system::env('BRANCH'),
    'commit'                 => system::env('COMMIT'),
    'node_group_id'          => system::env('NODE_GROUP_ID'),
    'node_group_environment' => system::env('NODE_GROUP_ENVIRONMENT'),
    'repo_target_branch'     => system::env('REPO_TARGET_BRANCH'),
    'environment_prefix'     => system::env('ENVIRONMENT_PREFIX'),
    'repo_type'              => system::env('REPO_TYPE'),
    'deployment_domain'      => system::env('DEPLOYMENT_DOMAIN'),
    'deployment_id'          => system::env('DEPLOYMENT_ID'),
    'deployment_token'       => system::env('DEPLOYMENT_TOKEN'),
    'deployment_owner'       => system::env('DEPLOYMENT_OWNER'),
  }

  # Wait for approval if the environment is protected
  $approval_info = cd4pe_deployments::wait_for_approval($deployment_info['node_group_environment'])

  # Create the signature
  $signature = deployment_signature::generate(
    ($deployment_info + $approval_info),
    $signing_secret,
  )

  # Register the signature
  $r = run_task(
    'deployment_signature::register',
    $signature_registration_target,
    {
      'commit_hash' => $deployment_info['commit'],
      'environment' => $deployment_info['node_group_environment'],
      'data'        => $signature,
    }
  )

  if $r.ok {
    return run_plan($underlying_policy, $underlying_policy_params)
  } else {
    fail_plan($r)
  }
}
