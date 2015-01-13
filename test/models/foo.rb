
if !ActiveRecordSpatialTestCase.table_exists?('foos')
  ActiveRecord::Migration.create_table(:foos) do |t|
    t.text :name
  end

  ARBC.execute(%{SELECT AddGeometryColumn('public', 'foos', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
  ARBC.execute(%{SELECT AddGeometryColumn('public', 'foos', 'the_other_geom', 4326, 'GEOMETRY', 2)})
end

class Foo < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  self.create_spatial_column_accessors!
end

