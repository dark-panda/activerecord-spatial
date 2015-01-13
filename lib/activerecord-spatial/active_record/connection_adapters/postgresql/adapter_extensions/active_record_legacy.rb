
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLColumn
      def simplified_type_with_spatial_type(field_type)
        case field_type
          # This is a special internal type used by PostgreSQL. In this case,
          # it is being used by the `geography_columns` view in PostGIS.
          when 'name'
            :string
          when /^geometry(\(|$)/
            :geometry
          when /^geography(\(|$)/
            :geography
          else
            simplified_type_without_spatial_type(field_type)
        end
      end
      alias_method_chain :simplified_type, :spatial_type
    end

    if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID)
      class PostgreSQLAdapter
        module OID
          class Spatial < Type
            def type_cast(value)
              value
            end
          end

          register_type 'geometry', OID::Spatial.new
          register_type 'geography', OID::Spatial.new
        end
      end
    end
  end
end

