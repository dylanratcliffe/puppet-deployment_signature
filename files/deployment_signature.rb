require 'yaml'
require 'jwt'

# Manages deployment signatures
class DeploymentSignature
  attr_reader :config
  attr_reader :signing_secret
  attr_reader :signature_location

  # Load the config that we will need to create the object
  def initialize(config_path = '/etc/puppetlabs/puppet/deployment_signatures.yaml')
    # Load the config
    @config = YAML.safe_load(File.read(config_path))

    # Load individual config items
    @signing_secret     = @config['signing_secret']
    @signature_location = @config['signature_location']
  rescue StandardError => e
    raise "Failed to load config at #{config_path}: #{e}"
  end

  def store(sha, environment, token)
    sig_path = "#{signature_location}/#{environment}"
    sig_file = "#{sig_path}/#{sha}.jwt"

    # Check the file doesn't already exist
    raise "Signature already exists at #{sig_file}" if File.exist?(sig_file)

    # Create the parent directory if required
    Dir.mkdir(sig_path) unless File.directory?(sig_path)
    
    # Check the signature is valid by decoding it. This will raise an error if
    # it fails
    decode(token)

    # Write the signature
    File.write(sig_file, token)
  end

  def valid?(token)
    data = decode(token)
    data.is_a? Array
  rescue
    false
  end

  def data(token)
    data = decode(token)
    data[0]
  end

  private

  def decode(token)
    JWT.decode(token, signing_secret)
  end
end
