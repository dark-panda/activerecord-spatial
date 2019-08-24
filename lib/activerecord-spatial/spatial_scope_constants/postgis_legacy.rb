# frozen_string_literal: true

module ActiveRecordSpatial
  module SpatialScopeConstants
    ONE_ARGUMENT_MEASUREMENTS = %w{
      3dlength_spheroid
      length2d_spheroid
      length_spheroid
    }

    ONE_GEOMETRY_ARGUMENT_MEASUREMENTS.concat(%w{
      distance_sphere
    })

    ZERO_ARGUMENT_MEASUREMENTS.concat(%w{
      length3d
      perimeter3d
    })

    ONE_ARGUMENT_MEASUREMENTS.concat(%w{
      length3d_spheroid
    })

    COMPATIBILITY_FUNCTION_ALIASES.merge!(
      'order_by_st_3dlength' => 'order_by_st_length3d',
      'order_by_st_3dperimeter' => 'order_by_st_perimeter3d',
      'order_by_st_3dlength_spheroid' => 'order_by_st_length3d_spheroid',
      'order_by_st_distancesphere' => 'order_by_st_distance_sphere'
    )
  end
end
