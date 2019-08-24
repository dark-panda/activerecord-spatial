# frozen_string_literal: true

module ActiveRecordSpatial
  module SpatialScopeConstants
    RELATIONSHIPS = %w{
      contains
      containsproperly
      covers
      coveredby
      crosses
      disjoint
      equals
      intersects
      orderingequals
      overlaps
      touches
      within
    }

    ZERO_ARGUMENT_MEASUREMENTS = %w{
      area
      ndims
      npoints
      nrings
      numgeometries
      numinteriorring
      numinteriorrings
      numpoints
      length
      length2d
      perimeter
      perimeter2d
    }

    ONE_GEOMETRY_ARGUMENT_MEASUREMENTS = %w{
      distance
      distancesphere
      maxdistance
    }

    ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS = %w{
      dwithin
      dfullywithin
    }

    FUNCTION_ALIASES = {
      'order_by_st_max_distance' => 'order_by_st_maxdistance',
      'st_geometrytype' => 'st_geometry_type'
    }

    COMPATIBILITY_FUNCTION_ALIASES = {}

    # Some functions were renamed or deprecated in PostGIS 2.2.
    if ActiveRecordSpatial::POSTGIS[:lib] >= '2.2'
      require 'activerecord-spatial/spatial_scope_constants/postgis_2_2'
    elsif ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      require 'activerecord-spatial/spatial_scope_constants/postgis_2_0'
    else
      require 'activerecord-spatial/spatial_scope_constants/postgis_legacy'
    end

    constants.each(&:freeze)
  end
end
