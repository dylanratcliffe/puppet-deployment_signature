#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../deployment_signature/files/deployment_signature.rb'
require 'json'
require 'fileutils'

params = JSON.parse(STDIN.read)
ds = DeploymentSignature.new

begin
  staging       = params['code_staging']
  environment   = File.join(staging, 'environments', params['environment'])
  r10k_json     = File.join(environment, '.r10k-deploy.json')
  filename_json = File.join(environment, '.deployment_signature.json')
  filename_jwt  = File.join(environment, '.deployment_signature.jwt')

  raise "#{r10k_json} does not exist, was this environment deployed with r10k?" unless File.file?(r10k_json)

  # Find the current commit hash
  r10k_deploy = JSON.parse(File.read(r10k_json))

  commit_hash = r10k_deploy['signature']

  # Read the token
  token_data = ds.retrieve_data(commit_hash, params['environment'])

  # Error checking
  raise "code_staging location does not exist: #{staging}" unless File.directory?(staging)
  raise "environment does not exist at: #{environment}" unless File.directory?(environment)


  # Write the files
  File.write(filename_json, token_data.to_json)
  File.write(filename_jwt, ds.retrieve_jwt(commit_hash, params['environment']))

  FileUtils.chown(params['owner'], params['group'], filename_json)
  FileUtils.chown(params['owner'], params['group'], filename_jwt)
  File.chmod(0640, filename_json)
  File.chmod(0640, filename_jwt)
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
  'result'    => 'success',
  'json_file' => filename_json,
  'jwt_file'  => filename_jwt,
  'data'      => token_data,
}.to_json)
exit 0
