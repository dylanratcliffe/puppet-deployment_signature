#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../deployment_signature/files/deployment_signature.rb'
require 'json'

params = JSON.parse(STDIN.read)
ds = DeploymentSignature.new

begin
  ds.store(params['commit_hash'], params['environment'], params['data'])
rescue StandardError => e
  puts({
    '_error' => {
      'msg'     => 'Could not register code signature',
      'kind'    => 'dylanratcliffe-deployment_signature/register-error',
      'details' => {
        'exception' => e.to_s,
      },
    },
  }.to_json)
  exit 1
end

puts({
  'result'      => 'success',
  'commit_hash' => params['commit_hash'],
}.to_json)
exit 0
