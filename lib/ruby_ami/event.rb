module RubyAMI
  class Event < Response
    attr_reader :name

    def initialize(name)
      super()
      @name = name
    end
  end
end # RubyAMI
