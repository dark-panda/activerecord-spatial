
module ActiveRecordSpatial
  # Creates named scopes for spatial relationships. The scopes created
  # follow the nine relationships established by the standard
  # Dimensionally Extended 9-Intersection Matrix functions plus a couple
  # of extra ones provided by PostGIS.
  #
  # Scopes provided are:
  #
  # * st_contains
  # * st_containsproperly
  # * st_covers
  # * st_coveredby
  # * st_crosses
  # * st_disjoint
  # * st_equals
  # * st_intersects
  # * st_orderingequals
  # * st_overlaps
  # * st_touches
  # * st_within
  # * st_dwithin
  # * st_dfullywithin
  #
  # The first argument to each of these methods can be a Geos::Geometry-based
  # object or anything readable by Geos.read along with an optional
  # options Hash.
  #
  # For ordering, we have the following:
  #
  # The following scopes take no arguments:
  #
  # * order_by_st_area
  # * order_by_st_ndims
  # * order_by_st_npoints
  # * order_by_st_nrings
  # * order_by_st_numgeometries
  # * order_by_st_numinteriorring
  # * order_by_st_numinteriorrings
  # * order_by_st_numpoints
  # * order_by_st_length3d
  # * order_by_st_length
  # * order_by_st_length2d
  # * order_by_st_perimeter
  # * order_by_st_perimeter2d
  # * order_by_st_perimeter3d
  #
  # These next scopes allow you to specify a geometry argument for
  # measurement:
  #
  # * order_by_st_distance
  # * order_by_st_distance_sphere
  # * order_by_st_maxdistance
  # * order_by_st_hausdorffdistance (additionally allows you to set the
  #   densify_frac argument)
  # * order_by_st_distance_spheroid (requires an additional SPHEROID
  #   string to calculate against)
  #
  # These next scopes allow you to specify a SPHEROID string to calculate
  # against:
  #
  # * order_by_st_length2d_spheroid
  # * order_by_st_length3d_spheroid
  # * order_by_st_length_spheroid
  #
  # == Options
  #
  # * :column - the column to compare against. This option can either be a
  #   straight-up column name or a Hash that contains a handful of options
  #   that can be used to wrap a geometry column in an ST_ function.
  #   When wrapping a geometry column in a function, you can set the name of
  #   the function and its methods like so:
  #
  #     Foo.st_within(geom, :column => {
  #       :name => :the_geom,
  #       :wrapper => :centroid
  #     })
  #
  #     Foo.st_within(geom, :column => {
  #       :wrapper => {
  #         :snap => [ 'POINT (0 0)', 1 ]
  #       }
  #     })
  #
  #   In the first example, the name of the function is the value to the
  #   :wrapper+ option. In the second example, +:snap+ is the function name
  #   and the Array value is used as the arguments to the +ST_snap+ function.
  #   We can also see the column name being set in the first example.
  #
  #   In all cases, the default column name is 'the_geom'. You can override
  #   the default column name for the ActiveRecordSpatial by setting it via
  #   ActiveRecordSpatial.default_column_name=, which is useful if you have
  #   a common geometry name you tend to use, such as +geom+, +wkb+,
  #   +feature+, etc.
  # * :use_index - whether to use the "ST_" methods or the "\_ST_"
  #   variants which don't use indexes. The default is true.
  # * :allow_null - relationship scopes have the option of treating NULL
  #   geometry values as TRUE, i.e.
  #
  #     ST_within(the_geom, ...) OR the_geom IS NULL
  #
  # * :desc - the order_by scopes have an additional :desc option to alllow
  #   for DESC ordering.
  # * :nulls - the order_by scopes also allow you to specify whether you
  #   want NULL values to be sorted first or last.
  # * :invert - inverts the relationship query from ST_*(A, B) to ST_*(B, A).
  #
  # Because it's quite common to only want to flip the ordering to DESC,
  # you can also just pass :desc on its own rather than as an options Hash.
  #
  # == SRID Detection
  #
  # * the default SRID according to the SQL-MM standard is 0, but versions
  #   of PostGIS prior to 2.0 would return -1. We do some detection here
  #   and set the value of ActiveRecordSpatial::UNKNOWN_SRIDS[type]
  #   accordingly.
  # * if the geometry itself has an SRID, we'll compare it to the
  #   geometry of the column. If they differ, we'll use ST_Transform
  #   to transform the geometry to the proper SRID for comparison. If
  #   they're the same, no conversion is necessary.
  # * if no SRID is specified in the geometry, we'll use ST_SetSRID
  #   to set the SRID to the column's SRID.
  # * in cases where the column has been defined with an SRID of
  #   UNKNOWN_SRIDS[type], no transformation is done, but we'll set the SRID
  #   of the geometry to UNKNOWN_SRIDS[type] to perform the query using
  #   ST_SetSRID, as we'll assume the SRID of the column to be whatever
  #   the SRID of the geometry is.
  # * when using geography types, the SRID is never transformed since
  #   it's assumed that all of your geometries will be in 4326.
  module SpatialScopes
    extend ActiveSupport::Concern

    DEFAULT_OPTIONS = {
      :column => ActiveRecordSpatial.default_column_name,
      :use_index => true
    }.freeze

    included do
      assert_arguments_length = proc { |args, min, max = (1.0 / 0.0)|
        raise ArgumentError.new("wrong number of arguments (#{args.length} for #{min}-#{max})") unless
          args.length.between?(min, max)
      }

      SpatialScopeConstants::RELATIONSHIPS.each do |relationship|
        src, line = <<-EOF, __LINE__ + 1
          scope :st_#{relationship}, lambda { |geom, options = {}|
            options = {
              :geom_arg => geom
            }.merge(options)

            unless geom.nil?
              self.where(
                ActiveRecordSpatial::SpatialFunction.build!(self, '#{relationship}', options).to_sql
              )
            end
          }
        EOF
        self.class_eval(src, __FILE__, line)
      end

      SpatialScopeConstants::ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS.each do |relationship|
        src, line = <<-EOF, __LINE__ + 1
          scope :st_#{relationship}, lambda { |geom, distance, options = {}|
            options = {
              :geom_arg => geom,
              :args => distance
            }.merge(options)

            self.where(
              ActiveRecordSpatial::SpatialFunction.build!(self, '#{relationship}', options).to_sql
            )
          }
        EOF
        self.class_eval(src, __FILE__, line)
      end

      self.class_eval do
        scope :st_geometry_type, lambda { |*args|
          assert_arguments_length[args, 1]
          options = args.extract_options!
          types = args

          self.where(
            ActiveRecordSpatial::SpatialFunction.build!(self, 'GeometryType', options).in(types).to_sql
          )
        }
      end

      SpatialScopeConstants::ZERO_ARGUMENT_MEASUREMENTS.each do |measurement|
        src, line = <<-EOF, __LINE__ + 1
          scope :order_by_st_#{measurement}, lambda { |options = {}|
            if options.is_a?(Symbol)
              options = {
                :desc => options
              }
            end

            function_call = ActiveRecordSpatial::SpatialFunction.build!(self, '#{measurement}', options).to_sql
            function_call << ActiveRecordSpatial::SpatialFunction.additional_ordering(options)

            self.order(function_call)
          }
        EOF
        self.class_eval(src, __FILE__, line)
      end

      SpatialScopeConstants::ONE_GEOMETRY_ARGUMENT_MEASUREMENTS.each do |measurement|
        src, line = <<-EOF, __LINE__ + 1
          scope :order_by_st_#{measurement}, lambda { |geom, options = {}|
            if options.is_a?(Symbol)
              options = {
                :desc => options
              }
            end

            options = {
              :geom_arg => geom
            }.merge(options)

            function_call = ActiveRecordSpatial::SpatialFunction.build!(self, '#{measurement}', options).to_sql
            function_call << ActiveRecordSpatial::SpatialFunction.additional_ordering(options)

            self.order(function_call)
          }
        EOF
        self.class_eval(src, __FILE__, line)
      end

      SpatialScopeConstants::ONE_ARGUMENT_MEASUREMENTS.each do |measurement|
        src, line = <<-EOF, __LINE__ + 1
          scope :order_by_st_#{measurement}, lambda { |argument, options = {}|
            options = {
              :args => argument
            }.merge(options)

            function_call = ActiveRecordSpatial::SpatialFunction.build!(self, '#{measurement}', options).to_sql
            function_call << ActiveRecordSpatial::SpatialFunction.additional_ordering(options)

            self.order(function_call)
          }
        EOF
        self.class_eval(src, __FILE__, line)
      end

      self.class_eval do
        scope :order_by_st_hausdorffdistance, lambda { |*args|
          assert_arguments_length[args, 1, 3]
          options = args.extract_options!
          geom, densify_frac = args

          options = {
            :geom_arg => geom,
            :args => densify_frac
          }.merge(options)

          function_call = ActiveRecordSpatial::SpatialFunction.build!(
            self,
            'hausdorffdistance',
            options
          ).to_sql
          function_call << ActiveRecordSpatial::SpatialFunction.additional_ordering(options)

          self.order(function_call)
        }

        scope :order_by_st_distance_spheroid, lambda { |geom, spheroid, options = {}|
          options = {
            :geom_arg => geom,
            :args => spheroid
          }.merge(options)

          function_call = ActiveRecordSpatial::SpatialFunction.build!(
            self,
            'distance_spheroid',
            options
          ).to_sql
          function_call << ActiveRecordSpatial::SpatialFunction.additional_ordering(options)

          self.order(function_call)
        }

        class << self
          aliases = SpatialScopeConstants::COMPATIBILITY_FUNCTION_ALIASES.merge(
            SpatialScopeConstants::FUNCTION_ALIASES
          )

          aliases.each do |k, v|
            alias_method(k, v)
          end
        end
      end
    end
  end

  # Alias for backwards compatibility.
  GeospatialScopes = SpatialScopes
end
