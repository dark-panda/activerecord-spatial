
require 'active_record/connection_adapters/postgresql_adapter'
require 'activerecord-spatial/active_record/connection_adapters/postgresql/adapter_extensions/active_record'

module ActiveRecordSpatial
  autoload :POSTGIS, 'activerecord-spatial/active_record/connection_adapters/postgresql/postgis'
  autoload :UNKNOWN_SRID, 'activerecord-spatial/active_record/connection_adapters/postgresql/unknown_srid'
  autoload :UNKNOWN_SRIDS, 'activerecord-spatial/active_record/connection_adapters/postgresql/unknown_srid'
end

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      def geometry_columns?
        true
      end

      def geography_columns?
        ActiveRecordSpatial::POSTGIS[:lib] >= '1.5'
      end
    end
  end
end
