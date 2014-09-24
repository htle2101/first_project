module Tire
  class Configuration
    def self.mapping_to_create_index(value = false)
      @mapping_to_create_index ||= value
    end
  end
end
