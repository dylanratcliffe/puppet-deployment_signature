# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @param signature_location Where on disk the signatures should be stored
# @param signing_secret Signing secret is used to actually *sign* the signature. The source of the signature needs to have the same value
#   as the destination for the signature to be verified. This means that even if a user was to get access to run the signature cration
#   task, they would also need to know the value of this secret for the signatures that it generates to be valid
# @param puppet_user The user that should own sugnatures, this should be the same user that the puppetserver runs as
# @param puppet_group The group that should own sugnatures, this should be the same group that the puppetserver runs as
#
# @example
#   include deployment_signature
class deployment_signature (
  Sensitive[String] $signing_secret = Sensitive('puppetlabs'),
  String $signature_location = 'TODO',
  String $puppet_user        = 'pe-puppet',
  String $puppet_group       = 'pe-puppet',
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
    content => Setsitive(to_yaml({
      'signing_secret'     => $signing_secret.unwrap,
      'signature_location' => $signature_location,
    })),
  }
}
