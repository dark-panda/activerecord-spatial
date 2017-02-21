
module ActiveRecordSpatial
  module SpatialScopeConstants
    ONE_ARGUMENT_MEASUREMENTS = %w{
      3dlength_spheroid
      length2d_spheroid
      length_spheroid
    }

    ONE_ARGUMENT_MEASUREMENTS.concat(%w{
      3dlength_spheroid
    })

    RELATIONSHIPS.concat(%w{
      3dintersects
    })

    ZERO_ARGUMENT_MEASUREMENTS.concat(%w{
      3dlength
      3dperimeter
    })

    ONE_GEOMETRY_ARGUMENT_MEASUREMENTS.concat(%w{
      3ddistance
      3dmaxdistance
      distance_sphere
    })

    ONE_GEOMETRY_ARGUMENT_AND_ONE_ARGUMENT_RELATIONSHIPS.concat(%w{
      3ddwithin
      3ddfullywithin
    })

    COMPATIBILITY_FUNCTION_ALIASES.merge!(
      'order_by_st_length3d' => 'order_by_st_3dlength',
      'order_by_st_perimeter3d' => 'order_by_st_3dperimeter',
      'order_by_st_length3d_spheroid' => 'order_by_st_3dlength_spheroid',
      'order_by_st_distancesphere' => 'order_by_st_distance_sphere'
    )

    FUNCTION_ALIASES.merge!(
      'st_3d_dwithin' => 'st_3ddwithin',
      'st_3d_dfully_within' => 'st_3ddfullywithin',
      'order_by_st_3d_distance' => 'order_by_st_3ddistance',
      'order_by_st_3d_max_distance' => 'order_by_st_3dmaxdistance'
    )
  end
end
