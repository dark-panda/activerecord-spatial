# frozen_string_literal: true

module ActiveRecord
  module Associations
    class SpatialAssociation < HasManyAssociation #:nodoc:
      def association_scope
        return unless klass

        @association_scope ||= SpatialAssociationScope.scope(self)
      end

      private

        def find_target
          scope = self.scope
          return scope.to_a if skip_statement_cache?(scope)

          conn = klass.connection

          # Since we're not using binds, we need to disable the scope cache,
          # basically, as otherwise the non-bound parameters we use will cause
          # cache misses that basically ignore subsequent scopes. This would
          # be much better to remove completely, but this will do for now
          # until we can find a better solution.
          reflection.clear_association_scope_cache

          sc = reflection.association_scope_cache(conn, owner) do |params|
            as = SpatialAssociationScope.create { params.bind }
            target_scope.merge!(as.scope(self))
          end

          binds = SpatialAssociationScope.get_bind_values(owner, reflection.chain)
          sc.execute(binds, conn) { |record| set_inverse_instance(record) } || []
        end

        def association_key_name
          SPATIAL_FIELD_ALIAS
        end
    end
  end
end
