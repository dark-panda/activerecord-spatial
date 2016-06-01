
if !ARBC.table_exists?('foobars')
  ActiveRecord::Migration.create_table(:foobars) do |t|
    t.text :name
  end

  ARBC.execute(%{SELECT AddGeometryColumn('public', 'foobars', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
  ARBC.execute(%{SELECT AddGeometryColumn('public', 'foobars', 'the_other_geom', 4326, 'GEOMETRY', 2)})
end

class Foobar < Foo
  self.table_name = 'foobars'
end
