module Tire
  module Model
    module Search
      module InstanceMethods

        def update_partial_index(partial_doc, options = {})
          id       = index.get_id_from_document(instance)
          type     = index.get_type_from_document(instance)
          if (unmatched_keys = partial_doc.symbolize_keys.keys - instance.class.mapping.keys).present?
            raise "These keys are not mapped with index. #{unmatched_keys}"
          end
          index.update(type, id, {:doc => partial_doc}, options)
          self
        end

        def update_index
          instance.send :_run_update_elasticsearch_index_callbacks do
            if instance.destroyed?
              index.remove instance
            else
              hash = instance.try(:to_hash) || {}
              response  = index.store( instance, {:percolate => percolator, :parent => hash[:_parent]} )
              instance.tire.matches = response['matches'] if instance.tire.respond_to?(:matches=)
              self
            end
          end
        end

        def to_indexed_json
          if instance.class.tire.mapping.empty?
            # Reject the id and type keys
            instance.to_hash.reject {|key,_| key.to_s == 'id' || key.to_s == 'type' }.to_json
          else
            mapping = instance.class.tire.mapping
            # Reject keys not declared in mapping
            hash = instance.to_hash.reject { |key, value| ! mapping.keys.map(&:to_s).include?(key.to_s) }

            # Evalute the `:as` options
            mapping.each do |key, options|
              case options[:as]
              when String
                hash[key] = instance.instance_eval(options[:as])
              when Proc
                hash[key] = instance.instance_eval(&options[:as])
              when Symbol
                hash[key] = instance.send(options[:as])
              end
            end

            hash.to_json
          end
        end
      end
    end
  end
end
