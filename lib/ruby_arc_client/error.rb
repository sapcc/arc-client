require "json"

module RubyArcClient

  class ArgumentError < StandardError; end

  class ApiError < StandardError
    attr_reader :json_data

    def initialize(json_data)
      super
      @json_data = json_data
    end

    def id
      @json_data[:id]
    end

    def status
      @json_data[:status]
    end

    def code
      @json_data[:code]
    end

    def title
      @json_data[:title]
    end

    def detail
      @json_data[:detail]
    end

    def source
      "#{@json_data.fetch(:source, {}).fetch(:pointer)} - #{@json_data.fetch(:source, {}).fetch(:parameter)}"
    end

    def to_s
      "#{@json_data.fetch(:title, "")} #{@json_data.fetch(:detail, "")}"
    end

  end

end