#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../deployment_signature/files/deployment_signature.rb'
require 'json'
require 'fileutils'

params = JSON.parse(STDIN.read)
ds = DeploymentSignature.new

begin
  # Read the token
  token_data = ds.retrieve(params['commit_hash'], params['environment'])
  
  staging = params['commit_hash']
  environment = File.join(staging, params['environment'])

  # Error checking
  raise "code_staging location does not exist: #{staging}" unless File.directory?(staging)
  raise "environment does not exist at: #{environment}" unless File.directory?(environment)

  filename = File.join(environment, ".deployment_signature.json")

  # Write the file
  File.write(filename, token_data.to_json)

  FileUtils.chown(params['owner'], params['group'], filename)
  File.chmod(0640, filename)
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
  'file'   => filename,
  'data'   => token_data,
}.to_json)
exit 0
