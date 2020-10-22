# frozen_string_literal: true

require 'spec_helper'
require_relative '../../files/deployment_signature.rb'

describe DeploymentSignature do
  before do
    @ds = described_class.new('./spec/example_config/deployment_signatures.yaml')
    @good_token = JWT.encode({'foo' => 'bar'}, @ds.signing_secret)
    @bad_token  = JWT.encode({'foo' => 'bar'}, 'wrong secret')
  end

  it 'Should throw an error for bad config' do
    expect { described_class.new }.to raise_error(/Failed to load config/)
  end

  it 'Should have loaded the signing secret' do
    expect(@ds.signing_secret).to eq("n9qx8273rgnoquwehfgbb987123ghb9y1g3b7d96zg127etydv2")
  end

  it 'Should have loaded the directory' do
    expect(@ds.signature_location).to eq("/tmp")
  end

  it 'Should be able to validate a good token' do
    expect(@ds.valid?(@good_token)).to be true
  end

  it 'Should be able to validate a bad token' do
    expect(@ds.valid?(@gbad_token)).to be false
  end

  it 'Should be able to extract data' do
    expect(@ds.data(@good_token)).to eq({
      'foo' => 'bar',
    })
  end

  it 'Should store a good token' do
    expect(File).to receive(:write).with(
      '/tmp/production/84f1d1edbc8924ea803ca309ae3119021acbbd4e.jwt',
      @good_token
    )

    @ds.store('84f1d1edbc8924ea803ca309ae3119021acbbd4e', 'production', @good_token)
  end
end
