# frozen_string_literal: true

$LOAD_PATH << File.dirname(__FILE__)
require 'test_helper'

class AdapterTests < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo)
  end

  def test_simplified_type
    geometry_columns = Foo.columns.select do |c|
      c.type == :geometry
    end

    other_columns = Foo.columns.select do |c|
      c.type != :geometry
    end

    assert_equal(2, geometry_columns.length)
    assert_equal(2, other_columns.length)
  end
end

if ActiveRecordSpatial.geography_columns?
  class AdapterWithGeographyTests < ActiveRecordSpatialTestCase
    def self.before_suite
      load_models(:foo_geography)
    end

    def test_simplified_type_geography
      geography_columns = FooGeography.columns.select do |c|
        c.type == :geography
      end

      other_columns = FooGeography.columns.select do |c|
        c.type != :geography
      end

      assert_equal(2, geography_columns.length)
      assert_equal(2, other_columns.length)
    end
  end
end
