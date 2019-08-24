# frozen_string_literal: true

$LOAD_PATH << File.dirname(__FILE__)
require 'test_helper'

class SpatialScopesTests < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :foo3d)
  end

  def ids_tester(method, args, ids = [], klass = Foo)
    geoms = klass.send(method, *Array.wrap(args))
    assert_equal(ids.sort, geoms.collect(&:id).sort)
  end

  def test_contains
    ids_tester(:st_contains, 'POINT(3 3)', [3])
  end

  def test_containsproperly
    ids_tester(:st_containsproperly, 'LINESTRING(-4 -4, 4 4)', [3])
  end

  def test_covers
    ids_tester(:st_covers, 'LINESTRING(-4 -4, 4 4)', [3])
  end

  def test_coveredby
    ids_tester(:st_coveredby, 'POLYGON((-6 -6, -6 6, 6 6, 6 -6, -6 -6))', [1, 3])
  end

  def test_crosses
    ids_tester(:st_crosses, 'LINESTRING(-6 -6, 4 4)', [3])
  end

  def test_disjoint
    ids_tester(:st_disjoint, 'POINT(100 100)', [1, 2, 3])
  end

  def test_equal
    ids_tester(:st_equals, 'POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', [3])
  end

  def test_intersects
    ids_tester(:st_intersects, 'LINESTRING(-5 -5, 10 10)', [1, 2, 3])
  end

  def test_orderingequals
    ids_tester(:st_orderingequals, 'POLYGON((-5 -5, -5 5, 5 5, 5 -5, -5 -5))', [3])
  end

  def test_overlaps
    ids_tester(:st_overlaps, 'POLYGON((-6 -6, -5 0, 0 0, 0 -5, -6 -6))', [3])
  end

  def test_touches
    ids_tester(:st_touches, 'POLYGON((-5 -5, -5 -10, -10 -10, -10 -5, -5 -5))', [3])
  end

  def test_within
    ids_tester(:st_within, 'POLYGON((-5 -5, 5 10, 20 20, 10 5, -5 -5))', [1, 2])
  end

  def test_dwithin
    ids_tester(:st_dwithin, ['POINT(5 5)', 10], [1, 2, 3])
  end

  def test_dfullywithin
    ids_tester(:st_dfullywithin, ['POINT(5 5)', 10], [1, 2])
  end

  def test_geometry_type
    ids_tester(:st_geometry_type, 'ST_Point', [1, 2])
    ids_tester(:st_geometry_type, %w{ ST_Point ST_Polygon }, [1, 2, 3])
    ids_tester(:st_geometry_type, ['ST_MultiLineString'], [])
  end

  def test_allow_null
    foo = Foo.create(name: 'four')
    ids_tester(:st_contains, ['POINT(3 3)', { allow_null: true }], [3, foo.id])
  ensure
    Foo.find_by_name('four').destroy
  end

  def test_nil_relationship
    assert_equal([1, 2, 3], Foo.st_within(nil).to_a.collect(&:id).sort)
  end

  def test_with_column
    assert_equal([1, 2, 3], Foo.st_disjoint('POINT(100 100)', column: :the_other_geom).to_a.collect(&:id).sort)
  end

  def test_with_srid_switching
    assert_equal([1, 2, 3], Foo.st_disjoint('SRID=4326; POINT(100 100)').to_a.collect(&:id).sort)
  end

  def test_with_srid_default
    assert_equal([1, 2, 3], Foo.st_disjoint('SRID=default; POINT(100 100)').to_a.collect(&:id).sort)
    assert_equal([3], Foo.st_contains('SRID=default; POINT(-3 -3)').to_a.collect(&:id).sort)
  end

  def test_with_srid_transform
    assert_equal([1, 2, 3], Foo.st_disjoint('SRID=4269; POINT(100 100)', column: :the_other_geom).to_a.collect(&:id).sort)
    assert_equal([3], Foo.st_contains('SRID=4269; POINT(7 7)', column: :the_other_geom).to_a.collect(&:id).sort)
  end

  def test_order_by_st_distance
    assert_equal([3, 1, 2], Foo.order_by_st_distance('POINT(1 1)').to_a.collect(&:id))
  end

  def test_order_by_st_distance_desc
    assert_equal([2, 1, 3], Foo.order_by_st_distance('POINT(1 1)', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_distance_sphere
    assert_equal([3, 1, 2], Foo.order_by_st_distance_sphere('POINT(1 1)').to_a.collect(&:id))
  end

  def test_order_by_st_distance_sphere_desc
    assert_equal([2, 1, 3], Foo.order_by_st_distance_sphere('POINT(1 1)', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_max_distance
    assert_equal([1, 3, 2], Foo.order_by_st_maxdistance('POINT(1 1)').to_a.collect(&:id))
  end

  def test_order_by_st_max_distance_desc
    assert_equal([2, 3, 1], Foo.order_by_st_maxdistance('POINT(1 1)', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_area
    assert_equal([1, 2, 3], Foo.order_by_st_area.to_a.collect(&:id))
  end

  def test_order_by_st_area_desc
    assert_equal([3, 1, 2], Foo.order_by_st_area(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_ndims
    assert_equal([1, 2, 3], Foo.order_by_st_ndims.to_a.collect(&:id))
  end

  def test_order_by_st_ndims_desc
    assert_equal([1, 2, 3], Foo.order_by_st_ndims(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_npoints
    assert_equal([1, 2, 3], Foo.order_by_st_npoints.to_a.collect(&:id))
  end

  def test_order_by_st_npoints_desc
    assert_equal([3, 1, 2], Foo.order_by_st_npoints(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_nrings
    assert_equal([1, 2, 3], Foo.order_by_st_nrings.to_a.collect(&:id))
  end

  def test_order_by_st_nrings_desc
    assert_equal([3, 1, 2], Foo.order_by_st_nrings(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_numgeometries
    assert_equal([1, 2, 3], Foo.order_by_st_numgeometries.to_a.collect(&:id))
  end

  def test_order_by_st_numgeometries_desc
    assert_equal([1, 2, 3], Foo.order_by_st_numgeometries(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_numinteriorring
    assert_equal([3, 1, 2], Foo.order_by_st_numinteriorring.to_a.collect(&:id))
  end

  def test_order_by_st_numinteriorring_desc
    assert_equal([1, 2, 3], Foo.order_by_st_numinteriorring(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_numinteriorrings
    assert_equal([3, 1, 2], Foo.order_by_st_numinteriorrings.to_a.collect(&:id))
  end

  def test_order_by_st_numinteriorrings_desc
    assert_equal([1, 2, 3], Foo.order_by_st_numinteriorrings(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_numpoints
    assert_equal([1, 2, 3], Foo.order_by_st_numpoints.order('id').to_a.collect(&:id))
  end

  def test_order_by_st_numpoints_desc
    assert_equal([1, 2, 3], Foo.order_by_st_numpoints(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_length3d
    assert_equal([1, 2, 3], Foo.order_by_st_length3d.order('id').to_a.collect(&:id))
  end

  def test_order_by_st_length3d_desc
    assert_equal([1, 2, 3], Foo.order_by_st_length3d(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_length
    assert_equal([1, 2, 3], Foo.order_by_st_length.to_a.collect(&:id))
  end

  def test_order_by_st_length_desc
    assert_equal([1, 2, 3], Foo.order_by_st_length(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_length2d
    assert_equal([1, 2, 3], Foo.order_by_st_length2d.order('id').to_a.collect(&:id))
  end

  def test_order_by_st_length2d_desc
    assert_equal([1, 2, 3], Foo.order_by_st_length2d(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_length3d_spheroid
    assert_equal([1, 2, 3], Foo.order_by_st_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]').to_a.collect(&:id))
  end

  def test_order_by_st_length3d_spheroid_desc
    expected = if ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      [3, 1, 2]
    else
      [1, 2, 3]
    end

    assert_equal(expected, Foo.order_by_st_length3d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_length2d_spheroid
    assert_equal([1, 2, 3], Foo.order_by_st_length2d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]').to_a.collect(&:id))
  end

  def test_order_by_st_length2d_spheroid_desc
    assert_equal([3, 1, 2], Foo.order_by_st_length2d_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_length_spheroid
    assert_equal([1, 2, 3], Foo.order_by_st_length_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]').to_a.collect(&:id))
  end

  def test_order_by_st_length_spheroid_desc
    expected = if ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      [3, 1, 2]
    else
      [1, 2, 3]
    end

    assert_equal(expected, Foo.order_by_st_length_spheroid('SPHEROID["WGS 84", 6378137, 298.257223563]', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_perimeter
    assert_equal([1, 2, 3], Foo.order_by_st_perimeter.to_a.collect(&:id))
  end

  def test_order_by_st_perimeter_desc
    assert_equal([3, 1, 2], Foo.order_by_st_perimeter(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_perimeter2d
    assert_equal([1, 2, 3], Foo.order_by_st_perimeter2d.to_a.collect(&:id))
  end

  def test_order_by_st_perimeter2d_desc
    assert_equal([3, 1, 2], Foo.order_by_st_perimeter2d(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_perimeter3d
    assert_equal([1, 2, 3], Foo.order_by_st_perimeter3d.order('id').to_a.collect(&:id))
  end

  def test_order_by_st_perimeter3d_desc
    assert_equal([3, 1, 2], Foo.order_by_st_perimeter3d(desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_hausdorffdistance
    assert_equal([1, 3, 2], Foo.order_by_st_hausdorffdistance('POINT(1 1)').to_a.collect(&:id))
  end

  def test_order_by_st_hausdorffdistance_desc
    assert_equal([2, 3, 1], Foo.order_by_st_hausdorffdistance('POINT(1 1)', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_hausdorffdistance_with_densify_frac
    assert_equal([1, 3, 2], Foo.order_by_st_hausdorffdistance('POINT(1 1)', 0.314).to_a.collect(&:id))
  end

  def test_order_by_st_distance_spheroid
    assert_equal([2, 3, 1], Foo.order_by_st_distance_spheroid('POINT(10 10)', 'SPHEROID["WGS 84", 6378137, 298.257223563]').to_a.collect(&:id))
  end

  def test_order_by_st_distance_spheroid_desc
    assert_equal([1, 3, 2], Foo.order_by_st_distance_spheroid('POINT(10 10)', 'SPHEROID["WGS 84", 6378137, 298.257223563]', desc: true).to_a.collect(&:id))
  end

  def test_order_by_st_area_with_desc_symbol
    assert_equal([3, 1, 2], Foo.order_by_st_area(:desc).to_a.collect(&:id))
  end

  def test_3dintersects
    skip('ST_3dintersects is unavailable') unless Foo3d.respond_to?(:st_3dintersects)

    expected = if ActiveRecordSpatial::POSTGIS[:lib] >= '2.2'
      [1, 2, 3]
    else
      [1, 3]
    end

    ids_tester(:st_3dintersects, 'LINESTRING(-5 -5 -5, 10 10 10)', expected, Foo3d)
  end

  def test_3ddistance
    skip('ST_3ddistance is unavailable') unless Foo3d.respond_to?(:order_by_st_3ddistance)

    expected = if ActiveRecordSpatial::POSTGIS[:lib] >= '2.2'
      [2, 3, 1]
    else
      [3, 2, 1]
    end

    assert_equal(expected, Foo3d.order_by_st_3ddistance('POINT(10 10)').to_a.collect(&:id))
  end

  def test_3dmaxdistance
    skip('ST_3dmaxdistance is unavailable') unless Foo3d.respond_to?(:order_by_st_3dmaxdistance)

    assert_equal([2, 1, 3], Foo3d.order_by_st_3dmaxdistance('POINT(10 10)').to_a.collect(&:id))
  end

  def test_3ddwithin
    skip('ST_3ddwithin is unavailable') unless Foo3d.respond_to?(:st_3ddwithin)

    ids_tester(:st_3ddwithin, ['LINESTRING(-5 -5 -5, 10 10 10)', 10], [1, 2, 3], Foo3d)
  end

  def test_3ddfullywithin
    skip('ST_3ddfullywithin is unavilable') unless Foo3d.respond_to?(:st_3ddfullywithin)

    ids_tester(:st_3ddfullywithin, ['LINESTRING(-10 -10 -10, 10 10 10)', 100], [1, 2, 3], Foo3d)
  end

  def test_order_by_with_column_wrapper
    values = nil

    assert_sql(/ST_envelope\("foos"."the_geom"\)/) do
      values = Foo.
        order_by_st_perimeter(
          desc: true,
          column: {
            wrapper: :envelope
          }
        ).to_a.collect(&:id)
    end

    assert_equal([3, 1, 2], values)
  end

  def test_order_by_with_column_wrapper_and_an_option
    values = nil

    assert_sql(/ST_geometryn\("foos"."the_geom", 1\)/) do
      values = Foo.
        order_by_st_perimeter(
          desc: true,
          column: {
            wrapper: {
              geometryn: 1
            }
          }
        ).to_a.collect(&:id)
    end

    assert_equal([3, 1, 2], values)
  end

  def test_order_by_with_column_wrapper_and_options
    values = nil

    assert_sql(/ST_snap\("foos"."the_geom", 'POINT \(0 0\)', 1.0\)/) do
      values = Foo.
        order_by_st_perimeter(
          desc: true,
          column: {
            wrapper: {
              snap: [
                'POINT (0 0)',
                1.0
              ]
            }
          }
        ).to_a.collect(&:id)
    end

    assert_equal([3, 1, 2], values)
  end

  def test_relationship_with_column_wrapper
    values = nil

    assert_sql(/ST_centroid\("foos"."the_geom"\)/) do
      values = Foo.
        st_within(
          'POLYGON((-5 -5, 5 10, 20 20, 10 5, -5 -5))',
          column: {
            wrapper: :centroid
          }
        ).to_a.collect(&:id)
    end

    assert_equal([1, 2, 3], values)
  end

  def test_relationship_with_column_wrapper_and_option
    values = nil

    assert_sql(/ST_geometryn\("foos"."the_geom", 1\)/) do
      values = Foo.
        st_within(
          'POLYGON((-5 -5, 5 10, 20 20, 10 5, -5 -5))',
          column: {
            wrapper: {
              geometryn: 1
            }
          }
        ).to_a.collect(&:id)
    end

    assert_equal([1, 2], values)
  end

  def test_relationship_with_column_wrapper_and_options
    values = nil

    assert_sql(/ST_snap\("foos"."the_geom", 'POINT \(0 0\)', 1.0\)/) do
      values = Foo.
        st_within(
          'POLYGON((-5 -5, 5 10, 20 20, 10 5, -5 -5))',
          column: {
            wrapper: {
              snap: [
                'POINT (0 0)',
                1.0
              ]
            }
          }
        ).to_a.collect(&:id)
    end

    assert_equal([1, 2], values)
  end
end
