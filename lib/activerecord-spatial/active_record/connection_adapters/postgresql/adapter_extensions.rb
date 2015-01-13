
require 'active_record/connection_adapters/postgresql_adapter'

if ActiveRecord::VERSION::STRING >= '4.2'
  require 'activerecord-spatial/active_record/connection_adapters/postgresql/adapter_extensions/active_record'
else
  require 'activerecord-spatial/active_record/connection_adapters/postgresql/adapter_extensions/active_record_legacy'
end

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

