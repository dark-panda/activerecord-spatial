
module ActiveRecord
  module Associations #:nodoc:
    class Preloader #:nodoc:
      class SpatialAssociation < HasMany #:nodoc:
        private

          def load_records(&block)
            return {} if owner_keys.empty?

            slices = owner_keys.each_slice(klass.connection.in_clause_length || owner_keys.size)
            @preloaded_records = slices.flat_map do |slice|
              records_for(slice).load(&block)
            end

            @preloaded_records.each_with_object({}) do |record, memo|
              keys = record[association_key_name].split(',')
              keys.each do |key|
                memo[key] ||= []
                memo[key] << record
              end
            end
          end

          def associated_records_by_owner(_preloader)
            records = load_records do |record|
              record[association_key_name].split(',').each do |key|
                owner = owners_by_key[convert_key(key)]
                association = owner.association(reflection.name)
                association.set_inverse_instance(record)
              end
            end

            owners.each_with_object({}) do |owner, result|
              result[owner] = records[convert_key(owner[owner_key_name])] || []
            end
          end
      end
    end

    class SpatialAssociation < HasManyAssociation #:nodoc:
      def association_scope
        return unless klass

        @association_scope ||= SpatialAssociationScope.scope(self, klass.connection)
      end

      private

        def get_records
          scope.to_a
        end
    end

    class SpatialAssociationScope < AssociationScope #:nodoc:
      INSTANCE = create

      class << self
        def scope(association, connection)
          INSTANCE.scope(association, connection)
        end
      end

      def last_chain_scope(scope, table, reflection, owner, assoc_klass)
        geom_options = {
          class: assoc_klass
        }

        if reflection.geom.is_a?(Hash)
          geom_options[:value] = owner[reflection.geom[:name]]
          geom_options.merge!(reflection.geom)
        else
          geom_options[:value] = owner[reflection.geom]
          geom_options[:name] = reflection.geom
        end

        scope = scope.send("st_#{reflection.relationship}", geom_options, reflection.scope_options)

        if reflection.type
          polymorphic_type = transform_value(owner.class.base_class.name)
          scope = scope.where(table.name => { reflection.type => polymorphic_type })
        end

        scope
      end
    end
  end
end
