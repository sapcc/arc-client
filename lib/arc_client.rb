require "arc_client/version"
require "arc_client/job"
require "arc_client/agent"
require "arc_client/tag"
require "arc_client/fact"
require "arc_client/error"
require "arc_client/user"

require 'rest-client'
require 'uri'
require 'ostruct'
require 'json'

module ArcClient

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
        raise ArcClient::ArgumentError, "Arc-Client: api_server_url not valid"
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
      $stderr.puts "Arc-Client: caught exception listing agents: #{e}"
      return Agents.new()
    end

    def list_agents!(token, filter = "", show_facts = [], page = 0, per_page = 0)
      if token == nil || token == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception listing agents. Token parameter not valid"
      end
      get_all_agents(token, filter, show_facts, page, per_page)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "filter" => filter, "show_facts" => show_facts, "page" => page, "per_page" => per_page} }}.to_json), e.message
      end
    end

    def find_agent(token, agent_id, show_facts = [])
      get_agent(token, agent_id, show_facts)
    rescue => e
      $stderr.puts "Arc-Client: caught exception finding an agent: #{e}"
      return nil
    end

    def find_agent!(token, agent_id, show_facts = [])
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception finding an agent. Parameter token or agent_id nil or empty"
      end
      get_agent(token, agent_id, show_facts)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "agent_id" => agent_id, "show_facts" => show_facts} }}.to_json), e.message
      end
    end

    def show_agent_facts(token, agent_id)
      get_all_facts(token, agent_id)
    rescue => e
      $stderr.puts "Arc-Client: caught exception listing agent facts: #{e}"
      return nil
    end

    def show_agent_facts!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception listing agent facts. Parameter token or agent_id nil or empty"
      end
      get_all_facts(token, agent_id)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "agent_id" => agent_id} }}.to_json), e.message
      end
    end

    def delete_agent(token, agent_id)
      response = remove_agent(token, agent_id)
      if response.code == 200
        return true
      else
        return false
      end
    rescue => e
      $stderr.puts "Arc-Client: caught exception deleting an agent: #{e}"
      return false
    end

    def delete_agent!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception deleting an agent. Parameter token or agent_id nil or empty"
      end
      response = remove_agent(token, agent_id)
      if response.code == 200
        return true
      else
        return false
      end
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s), "source" => {"pointer" => "", "parameter" => {"token" => token, "agent_id" => agent_id} }}.to_json), e.message
      end
    end

    def show_agent_tags(token, agent_id)
      show_tags_from_agent(token, agent_id)
    rescue => e
      $stderr.puts "Arc-Client: caught exception showing agent tags: #{e}"
      return nil
    end

    def show_agent_tags!(token, agent_id)
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception listing agent tags. Parameter token or agent_id nil or empty"
      end
      show_tags_from_agent(token, agent_id)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "agent_id" => agent_id} }}.to_json), e.message
      end
    end

    def add_agent_tags(token, agent_id, tags = {})
      add_tags_to_agent(token, agent_id, tags)
    rescue => e
      $stderr.puts "Arc-Client: caught exception adding agent tags: #{e}"
      return nil
    end

    def add_agent_tags!(token, agent_id, tags = {})
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception adding agent tags. Token or agent_id parameter not valid"
      end
      add_tags_to_agent(token, agent_id, tags)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "agent_id" => agent_id, "tags" => tags} }}.to_json), e.message
      end
    end

    def delete_agent_tag(token, agent_id, key = "")
      remove_tag_from_agent(token, agent_id, key)
    rescue => e
      $stderr.puts "Arc-Client: caught exception deleting agent tags: #{e}"
      return nil
    end

    def delete_agent_tag!(token, agent_id, key = "")
      if token == nil || token == '' || agent_id == nil || agent_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception adding agent tags. Token or agent_id parameter not valid"
      end
      remove_tag_from_agent(token, agent_id, key)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "agent_id" => agent_id, "key" => key} }}.to_json), e.message
      end
    end

    #
    # Jobs
    #

    def list_jobs(token, filter_by_agent_id = "", page = 0, per_page = 0)
      get_all_jobs(token, filter_by_agent_id, page, per_page)
    rescue => e
      $stderr.puts "Arc-Client: caught exception listing jobs: #{e}"
      return Jobs.new()
    end

    def list_jobs!(token, filter_by_agent_id = "", page = 0, per_page = 0)
      if token == nil || token == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception listing jobs. Token parameter not valid"
      end
      get_all_jobs(token, filter_by_agent_id, page, per_page)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "filter_by_agent_id" => filter_by_agent_id, "page" => page, "per_page" => per_page} }}.to_json), e.message
      end
    end

    def find_job(token, job_id)
      get_job(token, job_id)
    rescue => e
      $stderr.puts "Arc-Client: caught exception finding a job: #{e}"
      return nil
    end

    def find_job!(token, job_id)
      if token == nil || token == '' || job_id == nil || job_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception finding a job. Parameter token or job_id nil or empty"
      end
      get_job(token, job_id)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "job_id" => job_id} }}.to_json), e.message
      end
    end

    def find_job_log(token, job_id)
      get_job_log(token, job_id)
    rescue => e
      $stderr.puts "Arc-Client: caught exception getting a job log: #{e}"
      return ""
    end

    def find_job_log!(token, job_id)
      if token == nil || token == '' || job_id == nil || job_id == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception finding a job log. Parameter token or job_id nil or empty"
      end
      get_job_log(token, job_id)
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "job_id" => job_id} }}.to_json), e.message
      end
    end

    def execute_job(token, options)
      response = run_job(token, options)
      if response.nil?
        ""
      else
        response['request_id']
      end
    rescue => e
      $stderr.puts "Arc-Client: caught exception executing a job: #{e}"
      return ""
    end

    def execute_job!(token, options)
      if token == nil || token == ''
        raise ArcClient::ArgumentError, "Arc-Client: caught exception executing a job. Parameter token nil or empty"
      end
      response = run_job(token, options)
      if response.nil?
        ""
      else
        response['request_id']
      end
    rescue => e
      if e.respond_to? :response
        raise ApiError.new(e.response), e.message
      else
        raise ApiError.new({"id" => SecureRandom.hex(4).upcase,
                            "status" => "API Error",
                            "code" => 0,
                            "title" => e.message,
                            "detail" => CGI::escapeHTML(e.inspect.to_s),
                            "source" => {"pointer" => "", "parameter" => {"token" => token, "options" => options} }}.to_json), e.message
      end
    end

    private

    def show_tags_from_agent(token, agent_id)
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id + '/', "tags").to_s, {}, token, "")
      Tags.new(JSON.parse(response))
    end

    def add_tags_to_agent(token, agent_id, tags)
      tags_string = ''
      unless tags.empty?
        tags.each_with_index do |(key, value), index|
          tags_string << "#{key}=#{value}"
          if index < (tags.count - 1)
            tags_string << "&"
          end
        end
      end
      api_request('post', URI::join(@api_server_url, 'agents/', agent_id + '/', 'tags').to_s, {}, token, tags_string)
    end

    def remove_tag_from_agent(token, agent_id, key)
      api_request('delete', URI::join(@api_server_url, 'agents/', agent_id + '/', 'tags/' + key).to_s, {}, token, "")
    end

    def run_job(token, options)
      response = api_request('post', URI::join(@api_server_url, 'jobs').to_s, {}, token, options.to_json)
      JSON.parse(response)
    end

    def remove_agent(token, agent_id)
      api_request('delete', URI::join(@api_server_url, 'agents/', agent_id).to_s, {}, token, "")
    end

    def get_job_log(token, job_id)
      api_request('get', URI::join(@api_server_url, 'jobs/', job_id + '/', 'log').to_s, {}, token, "")
    end

    def get_job(token, job_id)
      response = api_request('get', URI::join(@api_server_url, 'jobs/', job_id).to_s, {}, token, "")
      job = Job.new(JSON.parse(response))
      if !job.user.nil?
        job.user = User.new(job.user)
      end
      return job
    end

    def get_all_jobs(token, filter_by_agent_id, page, per_page)
      jobs = []
      url = URI::join(@api_server_url, 'jobs').to_s
      parameters = {page: page, per_page: per_page, agent_id: filter_by_agent_id }
      response = api_request('get', url, parameters, token, "")
      hash_response = JSON.parse(response)
      hash_response.each do |j|
        job = Job.new(j)
        if !job.user.nil?
          job.user = User.new(job.user)
        end
        jobs << job
      end
      Jobs.new(jobs, Pagination.new(response.headers[:pagination_pages], response.headers[:pagination_elements]))
    end

    def get_all_facts(token, agent_id)
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id + '/', "facts").to_s, {}, token, "")
      Facts.new(JSON.parse(response))
    end

    def get_all_agents(token, filter, facts, page, per_page)
      agents = []
      parameters = {q: filter, page: page, per_page: per_page, facts: (facts.count() > 0 ? facts.join(',') : '') }
      response = api_request('get', URI::join(@api_server_url, 'agents').to_s, parameters, token, "")
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
      response = api_request('get', URI::join(@api_server_url, 'agents/', agent_id).to_s, {facts: (show_facts.count() > 0 ? show_facts.join(',') : '')}, token, "")
      agent = Agent.new(JSON.parse(response))
      if !agent.facts.nil?
        agent.facts = Facts.new(agent.facts)
      end
      return agent
    end

    # Rest-client
    # Due to unfortunate choices in the original API, the params used to populate the query string are actually
    # taken out of the headers hash. So if you want to pass both the params hash and more complex options,
    # use the special key :params in the headers hash.
    def api_request(method, uri, params={}, token, payload)
      RestClient::Request.execute(method: method.to_sym,
                                  url: uri,
                                  headers: {'X-Auth-Token': token, params: params},
                                  timeout: @timeout,
                                  payload: payload)
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
