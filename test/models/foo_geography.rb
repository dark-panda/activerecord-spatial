
unless ActiveRecordSpatialTestCase.table_exists?('foo_geographies')
  ActiveRecord::Migration.create_table(:foo_geographies) do |t|
    t.text :name
    t.column :the_geom, :geography
    t.column :the_other_geom, 'geography(Geometry, 4326)'
  end
end

class FooGeography < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  create_spatial_column_accessors!
end
