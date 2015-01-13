
module ActiveRecord
  module Associations #:nodoc:
    class SpatialAssociation < HasManyAssociation #:nodoc:
      def association_scope
        if klass
          @association_scope ||= SpatialAssociationScope.scope(self, klass.connection)
        end
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

      def last_chain_scope(scope, table, reflection, owner, tracker, assoc_klass)
        geom_options = {
          class: assoc_klass
        }

        if reflection.geom.is_a?(Hash)
          geom_options.merge!(
            value: owner[reflection.geom[:name]]
          )
          geom_options.merge!(reflection.geom)
        else
          geom_options.merge!(
            value: owner[reflection.geom],
            name: reflection.geom
          )
        end

        scope = scope.send("st_#{reflection.relationship}", geom_options, reflection.scope_options)

        if reflection.type
          value    = owner.class.base_class.name
          bind_val = bind scope, table.table_name, reflection.type, value, tracker
          scope    = scope.where(table[reflection.type].eq(bind_val))
        else
          scope
        end
      end
    end
  end
end

