# @summary Sets up the dependencies for using deployment signing
#
# Gives the Puppet server that is classififed with this class the ability to verify deployment signatures that were generated using the
# tasks and plans in this module. For this verification process to work, both the deployer and the deployment target must have
# pre-shared knowledge of the `signing_secret`
#
# @param signature_location Where on disk the signatures should be stored
# @param signing_secret Signing secret is used to actually *sign* the signature. The source of the signature needs to have the same value
#   as the destination for the signature to be verified. This means that even if a user was to get access to run the signature cration
#   task, they would also need to know the value of this secret for the signatures that it generates to be valid
# @param puppet_user The user that should own sugnatures, this should be the same user that the puppetserver runs as
# @param puppet_group The group that should own sugnatures, this should be the same group that the puppetserver runs as
# @param manage_jwt Whether the JWT gem should be managed by this class. If not it should be installed using some other method
# @param validators A series of scripts to execute to validate the deployment. These scripts will be run from the root of the deployed
#   controlrepo and will therefore be able to access the `.deployment_signature.*` files for pulling deployment information. Scripts
#   should exit 0 if the deployment should proceed and non-zero if it should fail. All scripts provided must exit 0 for the deployment to
#   proceed
#
# @example
#   include deployment_signature
class deployment_signature (
  Sensitive[String] $signing_secret     = Sensitive('puppetlabs'),
  String            $signature_location = '/etc/puppetlabs/puppet/deployment_signatures',
  String            $puppet_user        = 'pe-puppet',
  String            $puppet_group       = 'pe-puppet',
  Array[String]     $validators         = [],
  Boolean           $manage_jwt         = true
) {
  # This is a hardcoded location for the main config file. Since the tasks need to know where this is it will be static, and can point at
  # all the other information
  $config_file = '/etc/puppetlabs/puppet/deployment_signatures.yaml'

  file { $signature_location:
    ensure => 'directory',
    owner  => $puppet_user,
    group  => $puppet_group,
    mode   => '0750',
  }

  # Owned by root so that it can't be changed by an errant puppetserer
  file { $config_file:
    ensure  => 'file',
    owner   => $puppet_user,
    group   => $puppet_group,
    mode    => '0644',
    content => Sensitive(to_yaml({
      'signing_secret'     => $signing_secret.unwrap,
      'signature_location' => $signature_location,
      'validators'         => $validators,
    })),
  }

  if $manage_jwt {
    package { 'jwt':
      ensure   => 'present',
      provider => 'puppet_gem',
    }
  }
}
