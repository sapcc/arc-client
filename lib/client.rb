require "ruby-arc-client/version"
require 'rest-client'
require 'uri'

module Arc

  class Client
    attr_reader :api_server_url, :timeout

    DEFAULT_TIMEOUT = 10

    @api_server_url = nil
    @timeout = DEFAULT_TIMEOUT

    def initialize(api_server_url, timeout = DEFAULT_TIMEOUT)
      if !valid_url? api_server_url
        raise ArgumentError, "Ruby-Arc-Client: api_server_url not valid"
      end

      @timeout = timeout || DEFAULT_TIMEOUT
      @api_server_url = api_base_url(api_server_url)
    end

    #
    # Agents
    #

    def list_agents(token)
      response = api_request('get', URI::join(@api_server_url, 'agents').to_s, token)

      response.each do |raw_agent|
        Agent = Struct.new(raw_agent)
      end

    rescue Exception => e
      raise Exception, "Ruby-Arc-Client: caught exception listing agents: #{e}"
      return nil
    end

    def agent(token, agent_id)
      if agent_id == nil || agent_id == ''
        raise ArgumentError, "Ruby-Arc-Client: agent_id not valid"
      end
      api_request('get', URI::join(@api_server_url, 'agents', agent_id).to_s, token)
    end

    #
    # Jobs
    #

    def list_jobs(token)
      api_request('get', URI::join(@api_server_url, 'jobs').to_s, token)
    end


    private

    def api_request(method, uri, token)
      RestClient::Request.new(method: method.to_sym,
                              url: uri,
                              headers: {'X-Auth-Token': token},
                              timeout: @timeout).execute
    end

    def api_base_url(url)
      URI::join(url, '/api/v1/').to_s
    end

    def valid_url?(url)
      uri = URI.parse(url)
      uri.kind_of?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

  end

end
