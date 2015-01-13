
module ActiveRecordSpatial
  class SpatialRefSys < ::ActiveRecord::Base
    self.table_name = 'spatial_ref_sys'
    self.primary_key = 'srid'

    has_many :geometry_columns,
      foreign_key: :srid,
      inverse_of: :spatial_ref_sys

    has_many :geography_columns,
      foreign_key: :srid,
      inverse_of: :spatial_ref_sys

    def spatial_columns
      self.geometry_columns + self.geography_columns
    end
  end
end

