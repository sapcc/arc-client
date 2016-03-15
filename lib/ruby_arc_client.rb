require "ruby_arc_client/version"
require 'rest-client'
require 'uri'
require 'ostruct'
require 'json'

module RubyArcClient

  class Agent < OpenStruct
  end

  class Agents
    attr_reader :data, :pagination
    def initialize(_agents=[], _pagination=nil)
      @data = _agents
      @pagination = _pagination
    end
  end

  class Facts < OpenStruct
  end

  class Job < OpenStruct
  end

  class Jobs
    attr_reader :data, :pagination
    def initialize(_jobs=[], _pagination=nil)
      @data = _jobs
      @pagination = _pagination
    end
  end

  class Pagination
    attr_reader :total_pages, :total_elements

    def initialize(_total_pages=0, _total_elements=0)
      @total_pages = _total_pages.to_i
      @total_elements = _total_elements.to_i
    end

  end

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

    def list_agents(token, filter = "", show_facts = [], page = 0, per_page = 0)
      get_all_agents(token, filter, show_facts, page, per_page)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception listing agents: #{e}"
      return Agents.new()
    end

    def list_agents!(token, filter = "", show_facts = [], page = 0, per_page = 0)
      if token == nil || token == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception listing agents. Token parameter not valid"
      end
      get_all_agents(token, filter, show_facts, page, per_page)
    end

    def find_agent(token, agent_id, show_facts = [])
      get_agent(token, agent_id, show_facts)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception finding an agent: #{e}"
      return nil
    end

    def find_agent!(token, agent_id, show_facts = [])
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception finding an agent. Parameter token or agent_id nil or empty"
      end
      get_agent(token, agent_id, show_facts)
    end

    def show_agent_facts(token, agent_id)
      get_all_facts(token, agent_id)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception listing agent facts: #{e}"
      return nil
    end

    def show_agent_facts!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception listing agent facts. Parameter token or agent_id nil or empty"
      end
      get_all_facts(token, agent_id)
    end

    def delete_agent(token, agent_id)
      response = remove_agent(token, agent_id)
      if response.code == 200
        return true
      else
        return false
      end
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception deleting an agent: #{e}"
      return false
    end

    def delete_agent!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception deleting an agent. Parameter token or agent_id nil or empty"
      end
      response = remove_agent(token, agent_id)
      if response.code == 200
        return true
      else
        return false
      end
    end

    #
    # Jobs
    #

    def list_jobs(token, filter_by_agent_id = "", page = 0, per_page = 0)
      get_all_jobs(token, filter_by_agent_id, page, per_page)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception listing jobs: #{e}"
      return Jobs.new()
    end

    def list_jobs!(token, filter_by_agent_id = "", page = 0, per_page = 0)
      if token == nil || token == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception listing jobs. Token parameter not valid"
      end
      get_all_jobs(token, filter_by_agent_id, page, per_page)
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
      get_job_log(token, job_id)
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception getting a job log: #{e}"
      return ""
    end

    def find_job_log!(token, job_id)
      if token == nil || token == '' || job_id == nil || job_id == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception finding a job log. Parameter token or job_id nil or empty"
      end
      get_job_log(token, job_id)
    end

    def execute_job(token, options)
      response = run_job(token, options)
      if response.nil?
        ""
      else
        response['request_id']
      end
    rescue => e
      $stderr.puts "Ruby-Arc-Client: caught exception executing a job: #{e}"
      return ""
    end

    def execute_job!(token, options)
      if token == nil || token == ''
        raise ArgumentError, "Ruby-Arc-Client: caught exception executing a job. Parameter token nil or empty"
      end
      response = run_job(token, options)
      if response.nil?
        ""
      else
        response['request_id']
      end
    end

    private

    def run_job(token, options)
      response = api_request('post', URI::join(@api_server_url, 'jobs').to_s, token, options.to_json)
      JSON.parse(response)
    end

    def remove_agent(token, agent_id)
      api_request('delete', URI::join(@api_server_url, 'agents/', agent_id).to_s, token, "")
    end

    def get_job_log(token, job_id)
      api_request('get', URI::join(@api_server_url, 'jobs/', job_id + '/', 'log').to_s, token, "")
    end

    def get_job(token, job_id)
      response = api_request('get', URI::join(@api_server_url, 'jobs/', job_id).to_s, token, "")
      Job.new(JSON.parse(response))
    end

    def get_all_jobs(token, filter_by_agent_id, page, per_page)
      jobs = []
      url = URI::join(@api_server_url, 'jobs').to_s
      params = build_jobs_parameters_uri(filter_by_agent_id, page, per_page)
      if !params.empty?
        url += params
      end
      response = api_request('get', url, token, "")
      hash_response = JSON.parse(response)
      hash_response.each do |job|
        jobs << Job.new(job)
      end
      Jobs.new(jobs, Pagination.new(response.headers[:pagination_pages], response.headers[:pagination_elements]))
    end

    def build_jobs_parameters_uri(filter_by_agent_id, page, per_page)
      # set params
      uri_filter_by_agent_id = filter_by_agent_id.empty? ? '' : "agent_id=#{filter_by_agent_id}"
      uri_page = page == 0 ? '' : "page=#{page}"
      uri_per_page = per_page == 0 ? '' : "per_page=#{per_page}"

      # join params
      params = [uri_filter_by_agent_id, uri_page, uri_per_page].select{|x| x != ''}.join('&')
      params = '?' + params if !params.empty?

      return URI.encode(params)
    end

    def get_all_facts(token, agent_id)
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id + '/', "facts").to_s, token, "")
      Facts.new(JSON.parse(response))
    end

    def get_all_agents(token, filter, facts, page, per_page)
      agents = []
      parameters = build_agents_parameters_uri(filter, facts, page, per_page)
      response = api_request('get', URI::join(@api_server_url, 'agents', parameters).to_s, token, "")
      hash_response = JSON.parse(response)
      hash_response.each do |agent|
        agent = Agent.new(agent)
        # convert facts json to facts model
        if !agent.facts.nil?
          agent.facts = Facts.new(agent.facts)
        end
        agents << agent
      end
      agents
      Agents.new(agents, Pagination.new(response.headers[:pagination_pages], response.headers[:pagination_elements]))
    end

    def get_agent(token, agent_id, show_facts)
      parameter = build_agents_parameters_uri('', show_facts, '', '')
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id, parameter).to_s, token, "")
      agent = Agent.new(JSON.parse(response))
      if !agent.facts.nil?
        agent.facts = Facts.new(agent.facts)
      end
      return agent
    end

    def api_request(method, uri, token, payload)
      RestClient::Request.execute(method: method.to_sym,
                                  url: uri,
                                  headers: {'X-Auth-Token': token},
                                  timeout: @timeout,
                                  payload: payload)
    end

    def build_agents_parameters_uri(filter, facts, page, per_page)
      # set params
      uri_page = page == 0 ? '' : "page=#{page}"
      uri_per_page = per_page == 0 ? '' : "per_page=#{per_page}"
      uri_filter = filter.empty? ? '' : "q=#{filter}"
      uri_facts = facts.count() > 0 ? "facts=#{facts.join(',')}" : ''

      # join params
      params = [uri_filter, uri_facts, uri_page, uri_per_page].select{|x| x != ''}.join('&')
      params = '?' + params if !params.empty?

      return URI.encode(params)
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
