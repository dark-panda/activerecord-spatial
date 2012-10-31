
$: << File.dirname(__FILE__)
require 'test_helper'

class GeometryColumnTests < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo)
  end

  def test_geometry_columns_detected
    assert_equal(2, Foo.geometry_columns.length)
    assert_equal(0, Foo.geography_columns.length)

    Foo.geometry_columns.each do |column|
      assert_kind_of(ActiveRecordSpatial::GeometryColumn, column)
    end
  end

  def test_srid_for
    assert_equal(ActiveRecordSpatial::UNKNOWN_SRID, Foo.srid_for(:the_geom))
    assert_equal(4326, Foo.srid_for(:the_other_geom))
  end

  def test_coord_dimension_for
    assert_equal(2, Foo.coord_dimension_for(:the_geom))
    assert_equal(2, Foo.coord_dimension_for(:the_other_geom))
  end

  def test_geometry_column_by_name
    assert_kind_of(ActiveRecordSpatial::GeometryColumn, Foo.geometry_column_by_name(:the_geom))
    assert_kind_of(ActiveRecordSpatial::GeometryColumn, Foo.geometry_column_by_name(:the_other_geom))
  end

  def test_spatial_ref_sys
    assert_nil(Foo.geometry_column_by_name(:the_geom).spatial_ref_sys)
    assert_kind_of(ActiveRecordSpatial::SpatialRefSys, Foo.geometry_column_by_name(:the_other_geom).spatial_ref_sys)
    assert_equal(4326, Foo.geometry_column_by_name(:the_other_geom).spatial_ref_sys.srid)
  end
end

