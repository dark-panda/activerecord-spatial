
$: << File.dirname(__FILE__)
require 'test_helper'

class SpatialFunctionTests < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo)
    load_models(:blort)
  end

  def test_geom_arg_option
    assert_equal(
      %{ST_distance("foos"."the_geom", '010100000000000000000000000000000000000000'::geometry)},
      Foo.spatial_function(:distance, geom_arg: 'POINT(0 0)').to_sql
    )
  end

  def test_geom_as_argument
    assert_equal(
      %{ST_distance("foos"."the_geom", '010100000000000000000000000000000000000000'::geometry)},
      Foo.spatial_function(:distance, 'POINT(0 0)').to_sql
    )
  end

  def test_column_option
    assert_equal(
      %{ST_distance("foos"."the_other_geom", ST_SetSRID('010100000000000000000000000000000000000000'::geometry, 4326))},
      Foo.spatial_function(:distance, 'POINT(0 0)', column: 'the_other_geom').to_sql
    )
  end

  def test_class_option
    assert_equal(
      %{ST_distance("foos"."the_other_geom", ST_SetSRID('010100000000000000000000000000000000000000'::geometry, 4326))},
      Foo.spatial_function(:distance, {
        class: Blort,
        value: 'POINT(0 0)'
      }, {
        column: 'the_other_geom'
      }).to_sql
    )
  end

  def test_class_name_option
    assert_equal(
      %{ST_distance("foos"."the_other_geom", ST_SetSRID('010100000000000000000000000000000000000000'::geometry, 4326))},
      Foo.spatial_function(:distance, {
        class: 'Blort',
        value: 'POINT(0 0)'
      }, {
        column: 'the_other_geom'
      }).to_sql
    )
  end

  def test_invert_option
    assert_equal(
      %{ST_distance('010100000000000000000000000000000000000000'::geometry, "foos"."the_geom")},
      Foo.spatial_function(:distance, 'POINT(0 0)', invert: true).to_sql
    )
  end

  def test_use_index_option
    assert_equal(
      %{_ST_distance("foos"."the_geom", '010100000000000000000000000000000000000000'::geometry)},
      Foo.spatial_function(:distance, 'POINT(0 0)', use_index: false).to_sql
    )
  end

  def test_allow_null_option
    assert_equal(
      %{(ST_distance("foos"."the_geom", '010100000000000000000000000000000000000000'::geometry) OR "foos"."the_geom" IS NULL)},
      Foo.spatial_function(:distance, 'POINT(0 0)', allow_null: true).to_sql
    )
  end
end

