
unless ActiveRecordSpatialTestCase.table_exists?('zortables')
  ActiveRecord::Migration.create_table(:zortables) do |t|
    t.text :name
    t.text :zortable_type
  end

  ARBC.execute(%{SELECT AddGeometryColumn('public', 'zortables', 'zortable_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
end

class Zortable < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  create_spatial_column_accessors!
end
