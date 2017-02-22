
module ActiveRecord
  module Associations
    class Preloader #:nodoc:
      class SpatialAssociation < HasMany #:nodoc:
        if method_defined?(:query_scope)
          def query_scope(ids)
            spatial_query_scope(ids)
          end
        else
          def records_for(ids)
            spatial_query_scope(ids)
          end
        end

        private

          def association_key_name
            SPATIAL_FIELD_ALIAS
          end

          def spatial_query_scope(ids)
            join_name = model.quoted_table_name
            column = %{#{SPATIAL_JOIN_QUOTED_NAME}.#{model.quoted_primary_key}}
            geom = {
              class: model,
              table_alias: SPATIAL_JOIN_NAME
            }

            if reflection.options[:geom].is_a?(Hash)
              geom.merge!(reflection.options[:geom])
            else
              geom[:column] = reflection.options[:geom]
            end

            where_function = klass.send(
              "st_#{reflection.options[:relationship]}",
              geom,
              (reflection.options[:scope_options] || {}).merge(
                column: reflection.options[:foreign_geom]
              )
            )

            scope.
              select(%{#{klass.quoted_table_name}.*, array_to_string(array_agg(#{column}), ',') AS "#{SPATIAL_FIELD_ALIAS}"}).
              joins(
                "INNER JOIN #{join_name} AS #{SPATIAL_JOIN_QUOTED_NAME} ON (" <<
                  where_function.where_clause.send(:predicates).join(' AND ') <<
                  ')'
              ).
              where(model.arel_table.alias(SPATIAL_JOIN_NAME)[model.primary_key].in(ids)).
              group(table[klass.primary_key])
          end
      end
    end
  end
end
