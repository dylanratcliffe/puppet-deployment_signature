Puppet::Functions.create_function(:'deployment_signature::generate') do
  dispatch :generate do
    param 'Hash', :data
    param 'String[1]', :secret
  end

  def generate(data, secret)
    require 'jwt'

    JWT.encode(data, secret)
  end
end
