#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../deployment_signature/files/deployment_signature.rb'
require 'json'
require 'fileutils'
require 'open3'

params     = JSON.parse(STDIN.read)
ds         = DeploymentSignature.new
validators = []

begin
  staging     = params['code_staging']
  environment = File.join(staging, 'environments', params['environment'])
  validators  = ds.config['validators']

  raise 'Validators is not an array' unless validators.is_a? Array

  # cd into the correct location to run the commands
  Dir.chdir(environment) do
    validators.each do |validator|
      # Execute each of the validators and capture the output
      stdout, stderr, status = Open3.capture3(validator)

      # If validation failed then raise a detailed error
      unless status.success?
        puts({
          '_error' => {
            'msg'     => "Validator #{validator} failed. stdout: #{stdout}, stderr: #{stderr}",
            'kind'    => 'dylanratcliffe-deployment_signature/validate-failed-error',
            'details' => {
              'validator' => validator,
              'exit_code' => status.exitstatus,
              'stdout'    => stdout,
              'stderr'    => stderr,
            },
          },
        }.to_json)
        exit 1
      end
    end
  end
rescue StandardError => e
  puts({
    '_error' => {
      'msg'     => 'An exception occurred during validation',
      'kind'    => 'dylanratcliffe-deployment_signature/validate-error',
      'details' => {
        'exception' => e.to_s,
      },
    },
  }.to_json)
  exit 1
end

puts({
  'result'     => 'success',
  'validators' => validators,
}.to_json)
exit 0
