
unless ActiveRecordSpatialTestCase.table_exists?('foo3ds')
  ActiveRecord::Migration.create_table(:foo3ds) do |t|
    t.text :name
  end

  ARBC.execute(%{SELECT AddGeometryColumn('public', 'foo3ds', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 3)})
  ARBC.execute(%{SELECT AddGeometryColumn('public', 'foo3ds', 'the_other_geom', 4326, 'GEOMETRY', 3)})
end

class Foo3d < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  create_spatial_column_accessors!
end
