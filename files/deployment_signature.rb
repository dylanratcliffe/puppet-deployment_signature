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

  # Save a token to the storage location
  def store(sha, environment, token)
    path = sig_path(environment)
    file = sig_file(environment, sha)

    # Check the file doesn't already exist
    raise "Signature already exists at #{file}" if File.exist?(file)

    # Create the parent directory if required
    Dir.mkdir(path) unless File.directory?(path)
    
    # Check the signature is valid by decoding it. This will raise an error if
    # it fails
    decode(token)

    # Write the signature
    File.write(file, token)
  end

  def retrieve_jwt(sha, environment)
    file = sig_file(environment, sha)

    raise "Signature file #{file} does not exist" unless File.file?(file)

    return File.read(file)
  end

  def retrieve_data(sha, environment)
    return decode(retrieve_jwt(sha, environment))[0]
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

  def sig_path(environment)
    "#{signature_location}/#{environment}"
  end

  def sig_file(environment, sha)
    "#{sig_path(environment)}/#{sha}.jwt"
  end
end
