require "chart/version"
require "chart/time_util"
require "chart/user_stat"
require "chart/file_entity_stat"

module Chart
  class << self
    def load!
      if rails?
        register_rails_engine
      end
    end

    def register_rails_engine
      require 'chart/engine'
    end

    def rails?
      defined?(::Rails)
    end
  end
end

Chart.load!
