require 'ostruct'

module ArcClient

  class Agents
    attr_reader :data, :pagination
    def initialize(_agents=[], _pagination=nil)
      @data = _agents
      @pagination = _pagination
    end
  end

  class Agent < OpenStruct
  end

end