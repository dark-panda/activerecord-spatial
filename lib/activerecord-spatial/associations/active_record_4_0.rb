
module ActiveRecord
  module Associations #:nodoc:
    class SpatialAssociation < HasManyAssociation #:nodoc:
      def association_scope
        if klass
          @association_scope ||= SpatialAssociationScope.new(self).scope
        end
      end
    end

    class SpatialAssociationScope < AssociationScope #:nodoc:
      def add_constraints(scope)
        tables = construct_tables

        chain.each_with_index do |reflection, i|
          table, foreign_table = tables.shift, tables.first

          geom_options = {
            :class => reflection.klass
          }

          if reflection.geom.is_a?(Hash)
            geom_options.merge!(
              :value => owner[reflection.geom[:name]]
            )
            geom_options.merge!(reflection.geom)
          else
            geom_options.merge!(
              :value => owner[reflection.geom],
              :name => reflection.geom
            )
          end

          if reflection == chain.last
            scope = scope.send("st_#{reflection.relationship}", geom_options, reflection.scope_options)

            if reflection.type
              scope = scope.where(table[reflection.type].eq(owner.class.base_class.name))
            end
          else
            constraint = scope.where(
              scope.send(
                "st_#{reflection.relationship}",
                owner[reflection.foreign_geom],
                reflection.scope_options
              ).where_values
            ).join(' AND ')

            if reflection.type
              type = chain[i + 1].klass.base_class.name
              constraint = table[reflection.type].eq(type).and(constraint)
            end

            scope = scope.joins(join(foreign_table, constraint))
          end

          if reflection.options[:conditions].present?
            scope = scope.where(reflection.options[:conditions])
          end

          # Exclude the scope of the association itself, because that
          # was already merged in the #scope method.
          scope_chain[i].each do |scope_chain_item|
            klass = i == 0 ? self.klass : reflection.klass
            item  = eval_scope(klass, scope_chain_item)

            if scope_chain_item == self.reflection.scope
              scope.merge! item.except(:where, :includes)
            end

            scope.includes! item.includes_values
            scope.where_values += item.where_values
            scope.order_values |= item.order_values
          end
        end

        scope
      end
    end

    class Preloader #:nodoc:
      class SpatialAssociation < HasMany #:nodoc:
        private
          def associated_records_by_owner
            owners_map = owners_by_key
            owner_keys = owners_map.keys.compact

            if klass.nil? || owner_keys.empty?
              records = []
            else
              sliced  = owner_keys.each_slice(model.connection.in_clause_length || owner_keys.size)
              records = sliced.map { |slice| records_for(slice) }.flatten
            end

            records_by_owner = Hash[owners.map { |owner| [owner, []] }]

            records.each do |record|
              record[SPATIAL_FIELD_ALIAS].split(',').each do |owner_key|
                owners_map[owner_key].each do |owner|
                  records_by_owner[owner] << record
                end
              end
            end

            records_by_owner
          end
      end
    end
  end
end

