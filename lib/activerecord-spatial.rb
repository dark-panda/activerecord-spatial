
require 'geos-extensions'

require 'activerecord-spatial/active_record/connection_adapters/postgresql/adapter_extensions'

module ActiveRecordSpatial
  BASE_PATH = File.dirname(__FILE__)

  class << self
    def geometry_columns?
      ::ActiveRecord::Base.connection.geometry_columns?
    end

    def geography_columns?
      ::ActiveRecord::Base.connection.geography_columns?
    end
  end
end

require 'activerecord-spatial/active_record'

