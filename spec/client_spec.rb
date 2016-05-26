require 'spec_helper'
require 'securerandom'
require 'uri'

describe RubyArcClient do
  let(:token) { ENV['ARC_AUTH_TOKEN'] }
  let(:api_server_url) { 'https://arc-app' }

  it 'has a version number' do
    expect(RubyArcClient::VERSION).not_to be nil
  end

  context "creating" do

    it 'should raise an argument error with a no valid url' do
      expect { client = RubyArcClient::Client.new(nil) }.to raise_error { |error|
                                                    expect(error).to be_a(ArgumentError)
                                                  }

      expect { client = RubyArcClient::Client.new("") }.to raise_error { |error|
                                                   expect(error).to be_a(ArgumentError)
                                                 }

      expect { client = RubyArcClient::Client.new("no valid url") }.to raise_error { |error|
                                                               expect(error).to be_a(ArgumentError)
                                                             }
    end

    it 'should create base url' do
      client = RubyArcClient::Client.new("https://arc-app/miau/wau/bip")
      expect(client.api_server_url).to be == "https://arc-app/api/v1/"
    end

    it 'should set the default timeout' do
      client = RubyArcClient::Client.new(api_server_url, nil)
      expect(client.timeout).to be == 10
    end

    it 'should save the given timeout' do
      client = RubyArcClient::Client.new(api_server_url, 50)
      expect(client.timeout).to be == 50
    end

    it 'should return an instance' do
      expect { client = RubyArcClient::Client.new(api_server_url) }.to_not raise_error
    end

  end

  describe "Agents" do

    before(:each) do
      @client = RubyArcClient::Client.new(api_server_url)
    end

    context "list_agents" do

      it "should return all agents" do
        agents = @client.list_agents(token)
        expect(agents.data.count).to be > 0
      end

      it "should return agents filtered by os and online and return os fact" do
        agents = @client.list_agents(token, '@os="linux"', ['os'])
        expect(agents.data.count).to be > 0
        agents.data.each do |agent|
          expect(agent.facts.os).to be == 'linux'
        end
      end

      it "should rescue errors and return empty array" do
        agents = @client.list_agents("some_not_valid_token")
        expect(agents.data.count).to be == 0
      end

      it "should paginate" do
        agents = @client.list_agents(token, '', [], 1, 1)
        expect(agents.data.count).to be == 1
        expect(agents.pagination.total_elements).to be > 1
        expect(agents.pagination.total_pages).to be > 1
      end

    end

    context "list_agents!" do

      it "should return all agents" do
        agents = @client.list_agents!(token)
        expect(agents.data.count).to be > 0
      end

      it "should not rescue errors" do
        expect { @client.list_agents!("some_not_valid_token") }.to raise_error { |error|
                                                                     expect(error).to be_a(RestClient::Unauthorized)
                                                                   }
      end

      it "should return agents filtered by os and return os fact" do
        agents = @client.list_agents!(token, '@os="linux"', ['os'])
        expect(agents.data.count).to be > 0
        agents.data.each do |agent|
          expect(agent.facts.os).to be == 'linux'
        end
      end

      it "should paginate" do
        agents = @client.list_agents!(token, '', [], 1, 1)
        expect(agents.data.count).to be == 1
        expect(agents.pagination.total_elements).to be > 1
        expect(agents.pagination.total_pages).to be > 1
      end

    end

    context "find_agent" do

      it "should return an agent" do
        agents = @client.list_agents(token)
        agent = @client.find_agent(token, agents.data[0].agent_id)
        expect(agent).to_not be_nil
      end

      it "should return an agent with facts" do
        agents = @client.list_agents(token)
        agent = @client.find_agent(token, agents.data[0].agent_id, ['platform', 'online'])
        expect(agent).to_not be_nil
        expect(agent.facts.platform.empty?).to be == false
        expect(agent.facts.online).to be == true
      end

      it "should rescue errors and return nil" do
        agent = @client.find_agent(token, "some_not_existing_id")
        expect(agent).to be_nil
      end

    end

    context "find_agent!" do

      it "should return an agent" do
        agents = @client.list_agents(token)
        agent = @client.find_agent!(token, agents.data[0].agent_id)
        expect(agent).to_not be_nil
      end

      it "should return an agent with facts" do
        agents = @client.list_agents(token)
        agent = @client.find_agent!(token, agents.data[0].agent_id, ['platform', 'online'])
        expect(agent).to_not be_nil
        expect(agent.facts.platform.empty?).to be == false
        expect(agent.facts.online).to be == true
      end

      it "should not rescue errors" do
        expect { @client.find_agent!(token, "some_not_existing_id") }.to raise_error { |error|
                                                                           expect(error).to be_a(RestClient::ResourceNotFound)
                                                                         }
      end

    end

    context "list_facts" do

      it "should return the facts" do
        agents = @client.list_agents(token)
        facts = @client.show_agent_facts(token, agents.data[0].agent_id)
        expect(facts).to_not be_nil
      end

      it "should rescue errors and return nil" do
        facts = @client.show_agent_facts(token, "some_non_exisiting_id")
        expect(facts).to be_nil
      end

    end

    context "list_facts!" do

      it "should return the facts" do
        agents = @client.list_agents(token)
        facts = @client.show_agent_facts!(token, agents.data[0].agent_id)
        expect(facts).to_not be_nil
      end

      it "should rescue errors and return nil" do
        expect { @client.show_agent_facts!(token, "some_non_exisiting_id") }.to raise_error { |error|
                                                                                  expect(error).to be_a(RestClient::ResourceNotFound)
                                                                                }
      end

    end

    context "delete_agent" do

      it "should return true" do
        response = double("response", :code => 200)
        expect(@client).to receive(:remove_agent).with(token, "some_existing_agent_id").and_return(response)
        deleted = @client.delete_agent(token, "some_existing_agent_id")
        expect(deleted).to be == true
      end

      it "should rescue errors and return false" do
        deleted = @client.delete_agent(token, "some_non_exisiting_agent_id")
        expect(deleted).to be == false
      end

    end

    context "delete_agent!" do

      it "should return true" do
        response = double("response", :code => 200)
        expect(@client).to receive(:remove_agent).with(token, "some_existing_agent_id").and_return(response)
        deleted = @client.delete_agent!(token, "some_existing_agent_id")
        expect(deleted).to be == true
      end

      it "should not rescue errors" do
        expect { @client.delete_agent!(token, "some_non_exisiting_agent_id") }.to raise_error { |error|
                                                                                  expect(error).to be_a(RestClient::ResourceNotFound)
                                                                                }
      end

    end

    context "show_agent_tags" do

      it "shoud return the agent tags" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: 'tag1', test_tag2: 'tag2'}

        # save some tags
        @client.add_agent_tags(token, agent_id, tags)

        # get the tags
        new_tags = @client.show_agent_tags(token, agent_id)
        tags.each do |key, value|
          expect(new_tags.send(key.to_s)).to be == value
        end
      end

      it "should rescue errors" do
        tags = @client.show_agent_tags(token, 'some_non_exsiting_id')
        expect(tags).to be_nil
      end

    end

    context "show_agent_tags!" do

      it "shoud return the agent tags" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: 'tag1', test_tag2: 'tag2'}

        # save some tags
        @client.add_agent_tags(token, agent_id, tags)

        # get the tags
        new_tags = @client.show_agent_tags!(token, agent_id)
        tags.each do |key, value|
          expect(new_tags.send(key.to_s)).to be == value
        end
      end

      it "should not rescue errors" do
        expect {  @client.show_agent_tags!(token, 'some_non_exsiting_id') }.to raise_error { |error|
                                                                                    expect(error).to be_a(RestClient::ResourceNotFound)
                                                                                  }
      end

    end

    context "add_agent_tags" do

      it "should add the tags to the agent" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: SecureRandom.hex(10), test_tag2: SecureRandom.hex(10)}

        # save some tags
        @client.add_agent_tags(token, agent_id, tags)

        # get the tags
        new_tags = @client.show_agent_tags!(token, agent_id)
        tags.each do |key, value|
          expect(new_tags.send(key.to_s)).to be == value
        end
      end

      it "should rescue errors" do
        response = @client.add_agent_tags(token, 'some_non_exsiting_id')
        expect(response).to be_nil
      end

    end

    context "add_agent_tags!" do

      it "should add the tags to the agent" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: SecureRandom.hex(10), test_tag2: SecureRandom.hex(10)}

        # save some tags
        @client.add_agent_tags!(token, agent_id, tags)

        # get the tags
        new_tags = @client.show_agent_tags!(token, agent_id)
        tags.each do |key, value|
          expect(new_tags.send(key.to_s)).to be == value
        end
      end

      it "should not rescue errors" do
        expect {  @client.add_agent_tags!(token, 'non_existing_id') }.to raise_error { |error|
                                                                                 expect(error).to be_a(RestClient::ResourceNotFound)
                                                                               }
      end

    end

    context "delete_agent_tags" do

      it "should remove the tags" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: SecureRandom.hex(10), test_tag2: SecureRandom.hex(10)}

        # save some tags
        @client.add_agent_tags(token, agent_id, tags)

        # remove them
        tags.each do |key, value|
          @client.delete_agent_tag(token, agent_id, key.to_s)
        end

        # check if tags are there
        new_tags = @client.show_agent_tags!(token, agent_id)
        tags.each do |key, value|
          expect(new_tags.send(key.to_s)).to be == nil
        end
      end

      it "should rescue errors" do
        response = @client.delete_agent_tag(token, 'some_non_exsiting_id')
        expect(response).to be_nil
      end

    end

    context "delete_agent_tags!" do

      it "should remove the tags" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: SecureRandom.hex(10), test_tag2: SecureRandom.hex(10)}

        # save some tags
        @client.add_agent_tags(token, agent_id, tags)

        # remove them
        tags.each do |key, value|
          @client.delete_agent_tag!(token, agent_id, key.to_s)
        end

        # check if tags are there
        new_tags = @client.show_agent_tags!(token, agent_id)
        tags.each do |key, value|
          expect(new_tags.send(key.to_s)).to be == nil
        end
      end

      it "should not rescue errors" do
        expect {  @client.delete_agent_tag!(token, 'non_existing_id', 'some_key') }.to raise_error { |error|
                                                                           expect(error).to be_a(RestClient::ResourceNotFound)
                                                                         }
      end

      it "tests" do
        agents = @client.list_agents(token)
        agent_id = agents.data[0].agent_id
        tags = {test_tag1: SecureRandom.hex(10), test_tag2: SecureRandom.hex(10)}

        begin
          @client.delete_agent_tag!(token, agent_id, 'some key')
        rescue => e
          puts e.message
        end

      end

    end

  end

  describe "Jobs" do

    before(:each) do
      @client = RubyArcClient::Client.new(api_server_url)
    end

    context "list_jobs" do

      it "should return all jobs" do
        jobs = @client.list_jobs(token)
        expect(jobs.data.count).to be > 0
      end

      it "should return all jobs filtered by agent_id" do
        all_jobs = @client.list_jobs(token)
        jobs = @client.list_jobs(token, "25867b75-8181-4ae8-b0df-a0e39f5cdad3")
        expect(jobs.data.count).to be > 0
        expect(jobs.data.count).to be <= all_jobs.data.count
      end

      it "should rescue errors and return empty array" do
        jobs = @client.list_jobs("some_not_valid_token")
        expect(jobs.data.count).to be == 0
      end

      it "should paginate" do
        jobs = @client.list_jobs(token, "25867b75-8181-4ae8-b0df-a0e39f5cdad3", 1, 1)
        expect(jobs.data.count).to be == 1
        expect(jobs.pagination.total_elements).to be > 1
        expect(jobs.pagination.total_pages).to be > 1
      end

    end

    context "list_jobs!" do

      it "should return all jobs" do
        jobs = @client.list_jobs!(token)
        expect(jobs.data.count).to be > 0
      end

      it "should not rescue errors" do
        expect { @client.list_jobs!("some_not_valid_token") }.to raise_error { |error|
                                                                   expect(error).to be_a(RestClient::Unauthorized)
                                                                 }
      end

      it "should paginate" do
        jobs = @client.list_jobs!(token, "25867b75-8181-4ae8-b0df-a0e39f5cdad3", 1, 1)
        expect(jobs.data.count).to be == 1
        expect(jobs.pagination.total_elements).to be > 1
        expect(jobs.pagination.total_pages).to be > 1
      end

    end

    context "find_job" do

      it "should return a job" do
        jobs = @client.list_jobs(token)
        job = @client.find_job(token, jobs.data[0].request_id)
        expect(job).to_not be_nil
      end

      it "should rescue errors and return nil" do
        job = @client.find_job(token, "some_not_existing_id")
        expect(job).to be_nil
      end

    end

    context "find_job!" do

      it "should return a job" do
        jobs = @client.list_jobs(token)
        job = @client.find_job!(token, jobs.data[0].request_id)
        expect(job).to_not be_nil
      end

      it "should not rescue errors" do
        expect { @client.find_job!(token, "some_not_existing_id") }.to raise_error { |error|
                                                                           expect(error).to be_a(RestClient::ResourceNotFound)
                                                                         }
      end

    end

    context "find_job_log" do

      it "should return a job log" do
        jobs = @client.list_jobs(token)
        log = @client.find_job_log(token, jobs.data[0].request_id)
        expect(log).to_not be_nil
      end

      it "should rescue errors and return empty string" do
        log = @client.find_job_log(token, "some_not_existing_id")
        expect(log).to be == ""
      end

    end

    context "find_job_log!" do

      it "should return a job log" do
        jobs = @client.list_jobs(token)
        log = @client.find_job_log!(token, jobs.data[0].request_id)
        expect(log).to_not be_nil
      end

      it "should not rescue errors" do
        expect { @client.find_job_log!(token, "some_not_existing_id") }.to raise_error { |error|
                                                                         expect(error).to be_a(RestClient::ResourceNotFound)
                                                                       }
      end

    end

    context "execute_job" do

      it "should execute a job" do
        agents = @client.list_agents(token)
        options = {to: agents.data[0].agent_id, timeout: 15, agent: "execute", action: "script", payload: "echo \"Script start\"\n\nfor i in {1..10}\ndo\n\techo $i\n  sleep 1s\ndone\n\necho \"Script done\"" }
        job_id = @client.execute_job(token, options)
        expect(job_id.empty?).to be == false
      end

      it "should rescue errors and return empty string" do
        options = {to: "non_existing_agent_id", timeout: 15, agent: "execute", action: "script", payload: "echo \"Script start\"\n\nfor i in {1..10}\ndo\n\techo $i\n  sleep 1s\ndone\n\necho \"Script done\"" }
        job_id = @client.execute_job(token, options)
        expect(job_id.empty?).to be == true
      end

    end

    context "execute_job!" do

      it "should execute a job" do
        agents = @client.list_agents(token)
        options = {to: agents.data[0].agent_id, timeout: 15, agent: "execute", action: "script", payload: "echo \"Script start\"\n\nfor i in {1..10}\ndo\n\techo $i\n  sleep 1s\ndone\n\necho \"Script done\"" }
        job_id = @client.execute_job!(token, options)
        expect(job_id.empty?).to be == false
      end

      it "should rescue errors and return empty string" do
        options = {to: "non_existing_agent_id", timeout: 15, agent: "execute", action: "script", payload: "echo \"Script start\"\n\nfor i in {1..10}\ndo\n\techo $i\n  sleep 1s\ndone\n\necho \"Script done\"" }
        expect { @client.execute_job!(token, options) }.to raise_error { |error|
                                                                             expect(error).to be_a(RestClient::ResourceNotFound)
                                                                           }
      end

    end

  end

end
