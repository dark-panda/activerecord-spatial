# frozen_string_literal: true

module ActiveRecordSpatial
  class GeographyColumn < ActiveRecord::Base
    include SpatialColumn

    self.table_name = 'geography_columns'

    def spatial_type
      :geography
    end

    def spatial_column
      f_geography_column
    end
  end
end
