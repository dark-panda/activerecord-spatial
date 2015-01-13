
module ActiveRecord
  module Associations #:nodoc:
    class SpatialAssociation < HasManyAssociation #:nodoc:
      def association_scope
        if klass
          @association_scope ||= SpatialAssociationScope.scope(self, klass.connection)
        end
      end
    end

    class SpatialAssociationScope < AssociationScope #:nodoc:
      INSTANCE = new

      class << self
        def scope(association, connection)
          INSTANCE.scope(association, connection)
        end
      end

      private
        def add_constraints(scope, owner, assoc_klass, refl, tracker)
          chain = refl.chain
          scope_chain = refl.scope_chain

          tables = construct_tables(chain, assoc_klass, refl, tracker)

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
                value    = owner.class.base_class.name
                bind_val = bind scope, table.table_name, reflection.type.to_s, value, tracker
                scope    = scope.where(table[reflection.type].eq(bind_val))
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
                value    = chain[i + 1].klass.base_class.name
                bind_val = bind scope, table.table_name, reflection.type.to_s, value, tracker
                scope    = scope.where(table[reflection.type].eq(bind_val))
              end

              scope = scope.joins(join(foreign_table, constraint))
            end

            is_first_chain = i == 0
            klass = is_first_chain ? assoc_klass : reflection.klass

            # Exclude the scope of the association itself, because that
            # was already merged in the #scope method.
            scope_chain[i].each do |scope_chain_item|
              item  = eval_scope(klass, scope_chain_item, owner)

              if scope_chain_item == refl.scope
                scope.merge! item.except(:where, :includes, :bind)
              end

              if is_first_chain
                scope.includes! item.includes_values
              end

              scope.where_values += item.where_values
              scope.order_values |= item.order_values
            end
          end

          scope
        end
    end
  end
end

