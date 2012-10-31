
module ActiveRecordSpatial
  class GeographyColumn < ActiveRecord::Base
    include SpatialColumn

    self.table_name = 'geography_columns'

    def spatial_type
      :geography
    end

    def spatial_column
      self.f_geography_column
    end
  end
end

