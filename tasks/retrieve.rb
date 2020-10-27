#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../deployment_signature/files/deployment_signature.rb'
require 'json'

params = JSON.parse(STDIN.read)
ds = DeploymentSignature.new

begin
  token_data = ds.retrieve(params['commit_hash'], params['environment'])
rescue StandardError => e
  puts({
    '_error' => {
      'msg'     => 'Could not pull signature data',
      'kind'    => 'dylanratcliffe-deployment_signature/retrieve-error',
      'details' => {
        'exception' => e.to_s,
      },
    },
  }.to_json)
  exit 1
end

puts({
  'result' => 'success',
  'data'   => token_data,
}.to_json)
exit 0
