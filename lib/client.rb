require "ruby-arc-client/version"
require 'rest-client'
require 'uri'
require 'ostruct'
require 'yaml'

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
      get_all_agents(token)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception listing agents: #{e}"
      return []
    end

    def list_agents!(token)
      if token == nil || token == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception listing agents. Token parameter not valid"
      end
      get_all_agents(token)
    end

    def find_agent(token, agent_id)
      get_agent(token, agent_id)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception finding an agent: #{e}"
      return nil
    end

    def find_agent!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception finding an agent. Parameter token or agent_id nil or empty"
      end
      get_agent(token, agent_id)
    end

    def list_agent_facts(token, agent_id)
      get_all_facts(token, agent_id)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception listing agent facts: #{e}"
      return nil
    end

    def list_agent_facts!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception listing agent facts. Parameter token or agent_id nil or empty"
      end
      get_all_facts(token, agent_id)
    end

    def delete_agent(token, agent_id)
    end

    #
    # Jobs
    #

    def list_jobs(token)
      get_all_jobs(token)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception listing jobs: #{e}"
      return []
    end

    def list_jobs!(token)
      if token == nil || token == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception listing jobs. Token parameter not valid"
      end
      get_all_agents(token)
    end

    def find_job(token, job_id)
      get_job(token, job_id)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception finding a job: #{e}"
      return nil
    end

    def find_job!(token, job_id)
      if token == nil || token == '' || job_id == nil || job_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception finding a job. Parameter token or job_id nil or empty"
      end
      get_job(token, job_id)
    end

    def find_job_log(token, job_id)
    end

    def execute_job()
    end

    private

    def get_job(token, job_id)
      response = api_request('get', URI::join(@api_server_url, 'jobs/', job_id).to_s, token)
      Job.new(YAML.load(response))
    end

    def get_all_jobs(token)
      jobs = []
      response = api_request('get', URI::join(@api_server_url, 'jobs').to_s, token)
      hash_response = YAML.load(response)
      hash_response.each do |job|
        jobs << Job.new(job)
      end
      jobs
    end

    def get_all_facts(token, agent_id)
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id + '/', "facts").to_s, token)
      Facts.new(YAML.load(response))
    end

    def get_all_agents(token)
      agents = []
      response = api_request('get', URI::join(@api_server_url, 'agents').to_s, token)
      hash_response = YAML.load(response)
      hash_response.each do |agent|
        agents << Agent.new(agent)
      end
      agents
    end

    def get_agent(token, agent_id)
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id).to_s, token)
      Agent.new(YAML.load(response))
    end

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

  class Agent < OpenStruct
  end

  class Facts < OpenStruct
  end

  class Job < OpenStruct
  end

end
