
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
      distance_sphere
      maxdistance
    }

    ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS = %w{
      dwithin
      dfullywithin
    }

    ONE_ARGUMENT_MEASUREMENTS = %w{
      length2d_spheroid
      length_spheroid
    }

    # Some functions were renamed in PostGIS 2.0.
    if ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      RELATIONSHIPS.concat(%w{
        3dintersects
      })

      ZERO_ARGUMENT_MEASUREMENTS.concat(%w{
        3dlength
        3dperimeter
      })

      ONE_ARGUMENT_MEASUREMENTS.concat(%w{
        3dlength_spheroid
      })

      ONE_GEOMETRY_ARGUMENT_MEASUREMENTS.concat(%w{
        3ddistance
        3dmaxdistance
      })

      ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS.concat(%w{
        3ddwithin
        3ddfullywithin
      })
    else
      ZERO_ARGUMENT_MEASUREMENTS.concat(%w{
        length3d
        perimeter3d
      })

      ONE_ARGUMENT_MEASUREMENTS.concat(%w{
        length3d_spheroid
      })
    end

    FUNCTION_ALIASES = {
      'order_by_st_max_distance' => 'order_by_st_maxdistance',
      'st_geometrytype' => 'st_geometry_type'
    }

    COMPATIBILITY_FUNCTION_ALIASES = if ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      {
        'order_by_st_length3d' => 'order_by_st_3dlength',
        'order_by_st_perimeter3d' => 'order_by_st_3dperimeter',
        'order_by_st_length3d_spheroid' => 'order_by_st_3dlength_spheroid'
      }
    else
      {
        'order_by_st_3dlength' => 'order_by_st_length3d',
        'order_by_st_3dperimeter' => 'order_by_st_perimeter3d',
        'order_by_st_3dlength_spheroid' => 'order_by_st_length3d_spheroid'
      }
    end

    if ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      FUNCTION_ALIASES.merge!({
        'st_3d_dwithin' => 'st_3ddwithin',
        'st_3d_dfully_within' => 'st_3ddfullywithin',
        'order_by_st_3d_distance' => 'order_by_st_3ddistance',
        'order_by_st_3d_max_distance' => 'order_by_st_3dmaxdistance'
      })
    end
  end
end

