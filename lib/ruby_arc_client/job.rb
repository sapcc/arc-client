require 'ostruct'

module RubyArcClient

  class Jobs
    attr_reader :data, :pagination
    def initialize(_jobs=[], _pagination=nil)
      @data = _jobs
      @pagination = _pagination
    end
  end

  class Job < OpenStruct

    def completed?
      %w{complete completed}.include? self.status
    end
    def failed?
      self.status == "failed"
    end
    def running?
      !failed? && !completed?
    end
  end

end
