
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
              :class => model,
              :table_alias => SPATIAL_JOIN_NAME
            }

            if reflection.options[:geom].is_a?(Hash)
              geom.merge!(reflection.options[:geom])
            else
              geom[:column] = reflection.options[:geom]
            end

            scope.
              select(%{array_to_string(array_agg(#{column}), ',') AS "#{SPATIAL_FIELD_ALIAS}"}).
              joins(
                "INNER JOIN #{join_name} AS #{SPATIAL_JOIN_QUOTED_NAME} ON (" <<
                  klass.send("st_#{reflection.options[:relationship]}",
                    geom,
                    (reflection.options[:scope_options] || {}).merge(
                      :column => reflection.options[:foreign_geom]
                    )
                  ).where_values.join(' AND ') <<
                ")"
              ).
              where(model.arel_table.alias(SPATIAL_JOIN_NAME)[model.primary_key].in(ids)).
              group(table[klass.primary_key])
          end

          def load_slices(slices)
            @preloaded_records = slices.flat_map do |slice|
              records_for(slice)
            end

            @preloaded_records.each_with_object([]) do |record, memo|
              record[association_key_name].split(',').each do |key|
                memo << [ record, key ]
              end
            end
          end
      end
    end
  end
end

