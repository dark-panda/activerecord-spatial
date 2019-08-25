# frozen_string_literal: true

ActiveRecord::Schema.define do
  unless ARBC.data_source_exists?(:foos)
    create_table(:foos) do |t|
      t.text :name
    end

    ARBC.execute(%{SELECT AddGeometryColumn('public', 'foos', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
    ARBC.execute(%{SELECT AddGeometryColumn('public', 'foos', 'the_other_geom', 4326, 'GEOMETRY', 2)})
  end

  unless ARBC.data_source_exists?(:bars)
    create_table(:bars) do |t|
      t.text :name
    end

    ARBC.execute(%{SELECT AddGeometryColumn('public', 'bars', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
    ARBC.execute(%{SELECT AddGeometryColumn('public', 'bars', 'the_other_geom', 4326, 'GEOMETRY', 2)})
  end

  unless ARBC.data_source_exists?(:blorts)
    create_table(:blorts) do |t|
      t.text :name
      t.integer :foo_id
    end
  end

  unless ARBC.data_source_exists?(:foo_geographies)
    create_table(:foo_geographies) do |t|
      t.text :name
      t.column :the_geom, :geography
      t.column :the_other_geom, 'geography(Geometry, 4326)'
    end
  end

  unless ARBC.data_source_exists?(:foo3ds)
    create_table(:foo3ds) do |t|
      t.text :name
    end

    ARBC.execute(%{SELECT AddGeometryColumn('public', 'foo3ds', 'the_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 3)})
    ARBC.execute(%{SELECT AddGeometryColumn('public', 'foo3ds', 'the_other_geom', 4326, 'GEOMETRY', 3)})
  end

  unless ARBC.data_source_exists?(:zortables)
    create_table(:zortables) do |t|
      t.text :name
      t.text :zortable_type
    end

    ARBC.execute(%{SELECT AddGeometryColumn('public', 'zortables', 'zortable_geom', #{ActiveRecordSpatial::UNKNOWN_SRID}, 'GEOMETRY', 2)})
  end
end
