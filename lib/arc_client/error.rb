require "json"

module ArcClient

  class ArgumentError < StandardError; end

  class ApiError < StandardError
    attr_reader :json_data
    attr :json_hash

    def initialize(json_data)
      super
      @json_data = json_data
      begin
        @json_hash = JSON.parse(json_data)
      rescue
        @json_hash = {}
      end
    end

    def id
      @json_hash["id"]
    end

    def status
      @json_hash["status"]
    end

    def code
      @json_hash["code"]
    end

    def title
      @json_hash["title"]
    end

    def detail
      @json_hash["detail"]
    end

    def source
      "#{@json_hash.fetch("source", {}).fetch("pointer", '')} - #{@json_hash.fetch("source", {}).fetch("parameter", '')}"
    end

    def to_s
      if @json_hash.is_a?(Hash)
        return "#{@json_hash.fetch("title", "")} #{@json_hash.fetch("detail", "")}"
      else
        return @json_data
      end
    end

  end

end