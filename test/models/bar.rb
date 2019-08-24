# frozen_string_literal: true

unless ActiveRecordSpatialTestCase.table_exists?('bars')
  ActiveRecord::Migration.create_table(:bars) do |t|
    t.text :name
  end

  ARBC.execute(%{SELECT AddGeometryColumn('public', 'bars', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
  ARBC.execute(%{SELECT AddGeometryColumn('public', 'bars', 'the_other_geom', 4326, 'GEOMETRY', 2)})
end

class Bar < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  create_spatial_column_accessors!
end
