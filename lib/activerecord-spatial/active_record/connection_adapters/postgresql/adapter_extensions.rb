
require 'active_record/connection_adapters/postgresql_adapter'

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

    class PostgreSQLAdapter
      def geometry_columns?
        true
      end

      def geography_columns?
        ActiveRecordSpatial::POSTGIS[:lib] >= '1.5'
      end

      if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID)
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

module ActiveRecordSpatial
  autoload :POSTGIS, 'activerecord-spatial/active_record/connection_adapters/postgresql/postgis'
  autoload :UNKNOWN_SRID, 'activerecord-spatial/active_record/connection_adapters/postgresql/unknown_srid'
  autoload :UNKNOWN_SRIDS, 'activerecord-spatial/active_record/connection_adapters/postgresql/unknown_srid'
end

