
module ActiveRecordSpatial
  class GeometryColumn < ActiveRecord::Base
    include SpatialColumn

    self.table_name = 'geometry_columns'

    def spatial_type
      :geometry
    end

    def spatial_column
      self.f_geometry_column
    end
  end
end

