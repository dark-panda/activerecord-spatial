
require 'geos-extensions'

module ActiveRecordSpatial
  BASE_PATH = File.dirname(__FILE__)

  class << self
    def geometry_columns?
      ::ActiveRecord::Base.connection.geometry_columns?
    end

    def geography_columns?
      ::ActiveRecord::Base.connection.geography_columns?
    end

    def default_column_name
      @default_column_name ||= :the_geom
    end

    # Allows you to modify the default geometry column name for all of
    # ActiveRecordSpatial. This is useful when you have a common column name
    # for all of your geometry columns, such as +wkb+, +feature+, +geom+, etc.
    attr_writer :default_column_name
  end
end

require 'activerecord-spatial/active_record/connection_adapters/postgresql/adapter_extensions'
require 'activerecord-spatial/active_record'
