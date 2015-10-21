require 'spec_helper'

describe Arc do
  let(:token) { ENV['ARC_AUTH_TOKEN']  }
  let(:api_server_url) { 'https://arc-app' }

  it 'has a version number' do
    expect(Arc::VERSION).not_to be nil
  end

  context "creating" do

    it 'should raise an argument error with a no valid url' do
      expect { client = Arc::Client.new(nil) }.to raise_error { |error|
                                                    expect(error).to be_a(ArgumentError)
                                                  }

      expect { client = Arc::Client.new("") }.to raise_error { |error|
                                                   expect(error).to be_a(ArgumentError)
                                                 }

      expect { client = Arc::Client.new("no valid url") }.to raise_error { |error|
                                                               expect(error).to be_a(ArgumentError)
                                                             }
    end

    it 'should create base url' do
      client = Arc::Client.new("https://arc-app/miau/wau/bip")
      expect(client.api_server_url).to be == "https://arc-app/api/v1/"
    end

    it 'should set the default timeout' do
      client = Arc::Client.new(api_server_url, nil)
      expect(client.timeout).to be == 10
    end

    it 'should save the given timeout' do
      client = Arc::Client.new(api_server_url, 50)
      expect(client.timeout).to be == 50
    end

    it 'should return an instance' do
      expect { client = Arc::Client.new(api_server_url) }.to_not raise_error
    end

  end

  context "Agents" do

    it "should return all agents" do
      client = Arc::Client.new(api_server_url)
      puts client.list_agents(token)
    end

    it "should return an agent" do
      client = Arc::Client.new(api_server_url)
      puts client.agent('darwin', token)
    end

  end

end
