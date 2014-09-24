module Tire
  module Model
    module Indexing
      module ClassMethods
        def mapping(*args)
          @mapping ||= {}
          if block_given?
            @mapping_options = args.pop
            yield
            create_elasticsearch_index if Configuration.mapping_to_create_index
          else
            @mapping
          end
        end
      end
    end
  end
end
