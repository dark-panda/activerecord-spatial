
$: << File.dirname(__FILE__)
require 'test_helper'

class DefaultIntersectsRelationshipTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars
    end
  end

  def test_reflection
    assert_equal(:has_many, Foo.reflections[:bars].macro)
    assert_equal(:intersects, Foo.reflections[:bars].options[:relationship])
  end

  def test_association
    assert_equal([ 3 ], Foo.first.bars.collect(&:id).sort)
  end
end

class RelationshipsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)
  end

  {
    :contains => [],
    :containsproperly => [],
    :covers => [],
    :coveredby => [ 3 ],
    :crosses => [],
    :disjoint => [ 1, 2 ],
    :equals => [],
    :intersects => [ 3 ],
    :orderingequals => [],
    :overlaps => [],
    :touches => [],
    :within => [ 3 ],
    :'3dintersects' => [ 3 ]
  }.each do |relationship, ids|
    define_method("test_#{relationship}") do
      skip("ST_#{relationship} is unavailable") unless Foo.respond_to?("st_#{relationship}")

      Foo.reflections.delete(:bars)

      Foo.class_eval do
        has_many_spatially :bars, :relationship => relationship
      end

      assert_equal(:has_many, Foo.reflections[:bars].macro)
      assert_equal(relationship, Foo.reflections[:bars].options[:relationship])
      assert_equal(ids, Foo.first.bars.collect(&:id).sort)
    end
  end
end

class RelationshipsWithSelfTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)
  end

  {
    :contains => [ 1 ],
    :containsproperly => [ 1 ],
    :covers => [ 1 ],
    :coveredby => [ 1, 3 ],
    :crosses => [],
    :disjoint => [ 2 ],
    :equals => [ 1 ],
    :intersects => [ 1, 3 ],
    :orderingequals => [ 1 ],
    :overlaps => [],
    :touches => [],
    :within => [ 1, 3 ],
    :'3dintersects' => [ 1, 3 ]
  }.each do |relationship, ids|
    define_method("test_#{relationship}") do
      skip("ST_#{relationship} is unavailable") unless Foo.respond_to?("st_#{relationship}")

      Foo.reflections.delete(:foos)

      Foo.class_eval do
        has_many_spatially :foos, :relationship => relationship
      end

      assert_equal(:has_many, Foo.reflections[:foos].macro)
      assert_equal(relationship, Foo.reflections[:foos].options[:relationship])
      assert_equal(ids, Foo.first.foos.collect(&:id).sort)
    end
  end
end

class RelationshipsWithForeignGeomTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)
  end

  {
    :contains => [],
    :containsproperly => [],
    :covers => [],
    :coveredby => [ 3 ],
    :crosses => [],
    :disjoint => [ 1, 2 ],
    :equals => [],
    :intersects => [ 3 ],
    :orderingequals => [],
    :overlaps => [],
    :touches => [],
    :within => [ 3 ],
    :'3dintersects' => [ 3 ]
  }.each do |relationship, ids|
    define_method("test_#{relationship}") do
      skip("ST_#{relationship} is unavailable") unless Foo.respond_to?("st_#{relationship}")

      Foo.reflections.delete(:bars)

      Foo.class_eval do
        has_many_spatially :bars,
          :relationship => relationship,
          :foreign_geom => :the_other_geom
      end

      assert_equal(:has_many, Foo.reflections[:bars].macro)
      assert_equal(relationship, Foo.reflections[:bars].options[:relationship])
      assert_equal(:the_geom, Foo.reflections[:bars].options[:geom])
      assert_equal(:the_other_geom, Foo.reflections[:bars].options[:foreign_geom])
      assert_equal(ids, Foo.first.bars.collect(&:id).sort)
    end
  end
end

class RelationshipsWithGeomTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)
  end

  {
    :contains => [],
    :containsproperly => [],
    :covers => [],
    :coveredby => [ 3 ],
    :crosses => [],
    :disjoint => [ 1, 2 ],
    :equals => [],
    :intersects => [ 3 ],
    :orderingequals => [],
    :overlaps => [],
    :touches => [ 3 ],
    :within => [],
    :'3dintersects' => [ 3 ]
  }.each do |relationship, ids|
    define_method("test_#{relationship}") do
      skip("ST_#{relationship} is unavailable") unless Foo.respond_to?("st_#{relationship}")

      Foo.reflections.delete(:bars)

      Foo.class_eval do
        has_many_spatially :bars,
          :relationship => relationship,
          :geom => :the_other_geom
      end

      assert_equal(:has_many, Foo.reflections[:bars].macro)
      assert_equal(relationship, Foo.reflections[:bars].options[:relationship])
      assert_equal(:the_other_geom, Foo.reflections[:bars].options[:geom])
      assert_equal(:the_geom, Foo.reflections[:bars].options[:foreign_geom])
      assert_equal(ids, Foo.first.bars.collect(&:id).sort)
    end
  end
end

class CountsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_default_models
  end

  def test_count
    assert_equal(2, Foo.last.bars.count)
    assert_equal(2, Foo.last.foos.count)
  end
end

class WithCounterSqlTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)
  end

  def test_should_fail
    assert_raise(ArgumentError) do
      Foo.class_eval do
        has_many_spatially :bars,
          :class_name => 'Bar',
          :counter_sql => "SELECT COUNT(*) bars.* FROM bars"
      end
    end
  end
end

class ScopeOptionsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :scope_options => {
          :use_index => false
        }
    end
  end

  def test_use_index_false
    assert_sql(/_ST_intersects\(/) do
      Foo.first.bars.length
    end
  end
end

class PreloadTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_default_models
  end

  def test_without_eager_loading
    values = nil
    assert_queries(4) do
      assert_sql(/ST_intersects\('#{REGEXP_WKB_HEX}'::geometry, "bars"\."the_geom"/) do
        values = Foo.all.to_a.collect do |foo|
          foo.bars.length
        end
      end
    end

    assert_equal([ 1, 1, 2], values)
  end

  def test_with_eager_loading
    values = nil
    assert_queries(2) do
      assert_sql(/SELECT "bars"\.\*, array_to_string\(array_agg\("__spatial_ids_join__"."id"\), ','\) AS "__spatial_ids__" FROM "bars" INNER JOIN "foos" AS "__spatial_ids_join__" ON \(ST_intersects\("__spatial_ids_join__"."the_geom", "bars"."the_geom"\)\) WHERE "__spatial_ids_join__"\."id" IN \(.+\) GROUP BY "bars"\."id"/) do
        values = Foo.includes(:bars).to_a.collect do |foo|
          foo.bars.length
        end
      end
    end

    assert_equal([ 1, 1, 2 ], values)
  end
end

class PreloadWithOtherGeomTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :geom => :the_other_geom
    end
  end

  def test_without_eager_loading
    values = nil
    assert_queries(4) do
      assert_sql(/ST_intersects\(ST_SetSRID\('#{REGEXP_WKB_HEX}'::geometry, #{ActiveRecordSpatial::UNKNOWN_SRID}\), "bars"\."the_geom"/) do
        values = Foo.order('id').to_a.collect do |foo|
          foo.bars.length
        end
      end
    end

    assert_equal([ 1, 0, 2 ], values)
  end

  def test_with_eager_loading
    values = nil
    assert_queries(2) do
      assert_sql(/SELECT "bars"\.\*, array_to_string\(array_agg\("__spatial_ids_join__"."id"\), ','\) AS "__spatial_ids__" FROM "bars" INNER JOIN "foos" AS "__spatial_ids_join__" ON \(ST_intersects\(ST_SetSRID\("__spatial_ids_join__"."the_other_geom", #{ActiveRecordSpatial::UNKNOWN_SRID}\), "bars"."the_geom"\)\) WHERE "__spatial_ids_join__"\."id" IN \(.+\) GROUP BY "bars"\."id"/) do
        values = Foo.order('id').includes(:bars).to_a.collect do |foo|
          foo.bars.length
        end
      end
    end

    assert_equal([ 1, 0, 2 ], values)
  end
end

class OrderingTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :relationship => :disjoint,
        :order => 'ST_area(the_geom)'
    end
  end

  def test_ordering
    assert_equal([ 1, 2 ], Foo.first.bars.collect(&:id))
  end

  def test_reordering
    assert_equal([ 2, 1 ], Foo.first.bars.reorder('bars.id DESC').collect(&:id))
  end
end

class PolymorphicAssociationsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar, :zortable)

    Foo.class_eval do
      has_many_spatially :zortables,
        :as => :zortable
    end

    Bar.class_eval do
      has_many_spatially :zortables,
        :as => :zortable,
        :geom => :the_other_geom
    end
  end

  def test_without_eager_loading
    values = nil
    assert_queries(2) do
      assert_sql(/ST_intersects\('#{REGEXP_WKB_HEX}'::geometry, "zortables"\."zortable_geom"/) do
        values = Foo.first.zortables.collect(&:id).sort
      end
    end

    assert_equal([ 1, 7 ], values)
  end

  def test_without_eager_loading_and_geom
    values = nil
    assert_queries(2) do
      assert_sql(/ST_intersects\(ST_SetSRID\('#{REGEXP_WKB_HEX}'::geometry, #{ActiveRecordSpatial::UNKNOWN_SRID}\), "zortables"\."zortable_geom"/) do
        values = Bar.first.zortables.collect(&:id).sort
      end
    end

    assert_equal([ 6 ], values)
  end

  def test_with_eager_loading
    values = nil
    assert_queries(2) do
      assert_sql(/SELECT "zortables"\.\*, array_to_string\(array_agg\("__spatial_ids_join__"."id"\), ','\) AS "__spatial_ids__" FROM "zortables" INNER JOIN "foos" AS "__spatial_ids_join__" ON \(ST_intersects\("__spatial_ids_join__"."the_geom", "zortables"."zortable_geom"\)\) WHERE "zortables"."zortable_type" = 'Foo' AND "__spatial_ids_join__"\."id" IN \(.+\) GROUP BY "zortables"\."id"/) do
        values = Foo.includes(:zortables).first.zortables.collect(&:id).sort
      end
    end

    assert_equal([ 1, 7 ], values)
  end

  def test_with_eager_loading_and_geom
    values = nil
    assert_queries(2) do
      assert_sql(/SELECT "zortables"\.\*, array_to_string\(array_agg\("__spatial_ids_join__"."id"\), ','\) AS "__spatial_ids__" FROM "zortables" INNER JOIN "bars" AS "__spatial_ids_join__" ON \(ST_intersects\(ST_SetSRID\("__spatial_ids_join__"."the_other_geom", #{ActiveRecordSpatial::UNKNOWN_SRID}\), "zortables"."zortable_geom"\)\) WHERE "zortables"."zortable_type" = 'Bar' AND "__spatial_ids_join__"\."id" IN \(.+\) GROUP BY "zortables"\."id"/) do
        values = Bar.includes(:zortables).first.zortables.collect(&:id).sort
      end
    end

    assert_equal([ 6 ], values)
  end
end

class PolymorphicAssociationsWithRelationshipsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar, :zortable)
  end

  {
    :contains => [ 1 ],
    :containsproperly => [ 1 ],
    :covers => [ 1 ],
    :coveredby => [ 1, 7 ],
    :crosses => [],
    :disjoint => [ 2, 3 ],
    :equals => [ 1 ],
    :intersects => [ 1, 7 ],
    :orderingequals => [ 1 ],
    :overlaps => [],
    :touches => [],
    :within => [ 1, 7 ],
    :'3dintersects' => [ 1, 7 ]
  }.each do |relationship, ids|
    define_method("test_#{relationship}") do
      skip("ST_#{relationship} is unavailable") unless Foo.respond_to?("st_#{relationship}")

      Foo.reflections.delete(:zortables)

      Foo.class_eval do
        has_many_spatially :zortables,
          :as => :zortable,
          :relationship => relationship
      end

      assert_equal(ids, Foo.first.zortables.collect(&:id).sort)
      assert_equal(ids, Foo.includes(:zortables).first.zortables.collect(&:id).sort)
    end
  end
end

class ClassNameOptionTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :blops,
        :class_name => 'Bar'
    end
  end

  def test_class_name
    assert_equal([ 3 ], Foo.first.blops.collect(&:id))
    assert_equal([ 3 ], Foo.includes(:blops).first.blops.collect(&:id))
  end
end

class ConditionsOptionTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :relationship => :disjoint,
        :conditions => {
          :bars => {
            :id => 3
          }
        }
    end
  end

  def test_conditions
    assert_equal([], Foo.first.bars.collect(&:id))
    assert_equal([], Foo.includes(:bars).first.bars.collect(&:id))
  end
end

class IncludeOptionTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:blort, :foo, :bar)

    Foo.class_eval do
      has_many :blorts
    end

    Bar.class_eval do
      has_many_spatially :foos,
        :include => :blorts
    end
  end

  def test_includes
    skip("Removed from AR 4") if ActiveRecord::VERSION::MAJOR >= 4

    values = nil
    assert_queries(3) do
      assert_sql(/SELECT\s+"blorts"\.\*\s+FROM\s+"blorts"\s+WHERE\s+"blorts"\."foo_id"\s+IN\s+\(.+\)/) do
        values = Bar.first.foos.collect(&:id)
      end
    end

    assert_equal([ 3 ], values)
  end
end

class GeomWrapperTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :geom => {
          :wrapper => :envelope
        }
    end
  end

  def test_without_eager_loading
    values = nil

    assert_sql(/ST_intersects\(ST_envelope\('#{REGEXP_WKB_HEX}'::geometry\), "bars"."the_geom"\)/) do
      values = Foo.first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end

  def test_with_eager_loading
    values = nil

    assert_sql(/ST_intersects\(ST_envelope\("__spatial_ids_join__"."the_geom"\), "bars"."the_geom"\)/) do
      values = Foo.includes(:bars).first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end
end

class ForeignGeomWrapperTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :foreign_geom => {
          :wrapper => :envelope
        }
    end
  end

  def test_without_eager_loading
    values = nil

    assert_sql(/ST_envelope\("bars"."the_geom"\)/) do
      values = Foo.first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end

  def test_with_eager_loading
    values = nil

    assert_sql(/ST_intersects\("__spatial_ids_join__"."the_geom", ST_envelope\("bars"."the_geom"\)\)/) do
      values = Foo.includes(:bars).first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end
end

class BothGeomWrapperTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :geom => {
          :wrapper => :convexhull
        },
        :foreign_geom => {
          :wrapper => :envelope
        }
    end
  end

  def test_without_eager_loading
    values = nil

    assert_sql(/ST_convexhull\('#{REGEXP_WKB_HEX}'::geometry\), ST_envelope\("bars"."the_geom"\)/) do
      values = Foo.first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end

  def test_with_eager_loading
    values = nil

    assert_sql(/ST_intersects\(ST_convexhull\("__spatial_ids_join__"."the_geom"\), ST_envelope\("bars"."the_geom"\)\)/) do
      values = Foo.includes(:bars).first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end
end

class BothGeomWrapperWithMixedSRIDsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :geom => {
          :wrapper => :convexhull
        },
        :foreign_geom => {
          :wrapper => :centroid,
          :name => :the_other_geom
        }
    end
  end

  def test_without_eager_loading
    values = nil

    assert_sql(/ST_convexhull\(ST_SetSRID\('#{REGEXP_WKB_HEX}'::geometry, 4326\)\), ST_centroid\("bars"."the_other_geom"\)/) do
      values = Foo.first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end

  def test_with_eager_loading
    values = nil

    assert_sql(/ST_intersects\(ST_convexhull\(ST_SetSRID\("__spatial_ids_join__"."the_geom", 4326\)\), ST_centroid\("bars"."the_other_geom"\)\)/) do
      values = Foo.includes(:bars).first.bars.collect(&:id).sort
    end

    assert_equal([ 3 ], values)
  end
end

class BothGeomWrapperAndOptionsWithMixedSRIDsTest < ActiveRecordSpatialTestCase
  def self.before_suite
    load_models(:foo, :bar)

    Foo.class_eval do
      has_many_spatially :bars,
        :class_name => 'Bar',
        :geom => {
          :wrapper => :convexhull
        },
        :foreign_geom => {
          :wrapper => {
            :buffer => 100
          },
          :name => :the_other_geom
        }
    end
  end

  def test_without_eager_loading
    values = nil

    assert_sql(/ST_convexhull\(ST_SetSRID\('#{REGEXP_WKB_HEX}'::geometry, 4326\)\), ST_buffer\("bars"."the_other_geom", 100\)/) do
      values = Foo.first.bars.collect(&:id).sort
    end

    assert_equal([ 1, 2, 3 ], values)
  end

  def test_with_eager_loading
    values = nil

    assert_sql(/ST_intersects\(ST_convexhull\(ST_SetSRID\("__spatial_ids_join__"."the_geom", 4326\)\), ST_buffer\("bars"."the_other_geom", 100\)\)/) do
      values = Foo.includes(:bars).first.bars.collect(&:id).sort
    end

    assert_equal([ 1, 2, 3 ], values)
  end

  class ScopeArgumentTest < ActiveRecordSpatialTestCase
    def setup
      self.class.load_models(:foo, :bar, :blort)
    end

    def test_foo
      Foo.class_eval do
        has_many_spatially :bars, proc {
          self.order(:id)
        }
      end

      assert_sql(/ORDER BY "bars"."id"/) do
        Foo.first.bars.to_a
      end
    end
  end if ActiveRecord::VERSION::MAJOR >= 4
end

