
$: << File.dirname(__FILE__)
require 'test_helper'

class GeographyColumnTests < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo_geography)
  end

  def test_geography_columns_detected
    assert_equal(0, FooGeography.geometry_columns.length)
    assert_equal(2, FooGeography.geography_columns.length)

    FooGeography.geography_columns.each do |column|
      assert_kind_of(ActiveRecordSpatial::GeographyColumn, column)
    end
  end

  def test_srid_for
    assert_equal(ActiveRecordSpatial::UNKNOWN_SRIDS[:geography], FooGeography.srid_for(:the_geom))
    assert_equal(4326, FooGeography.srid_for(:the_other_geom))
  end

  def test_coord_dimension_for
    assert_equal(2, FooGeography.coord_dimension_for(:the_geom))
    assert_equal(2, FooGeography.coord_dimension_for(:the_other_geom))
  end

  def test_geography_column_by_name
    assert_kind_of(ActiveRecordSpatial::GeographyColumn, FooGeography.geography_column_by_name(:the_geom))
    assert_kind_of(ActiveRecordSpatial::GeographyColumn, FooGeography.geography_column_by_name(:the_other_geom))
  end

  def test_spatial_ref_sys
    assert_nil(FooGeography.geography_column_by_name(:the_geom).spatial_ref_sys)
    assert_kind_of(ActiveRecordSpatial::SpatialRefSys, FooGeography.geography_column_by_name(:the_other_geom).spatial_ref_sys)
    assert_equal(4326, FooGeography.geography_column_by_name(:the_other_geom).spatial_ref_sys.srid)
  end
end

