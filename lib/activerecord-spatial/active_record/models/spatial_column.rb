
module ActiveRecordSpatial
  module SpatialColumn #:nodoc:
    extend ActiveSupport::Concern

    included do
      self.primary_key = nil

      # PostGIS inserts a "type" column into these tables/views that can
      # really mess things up good.
      self.inheritance_column = 'nonexistent_column_name_type'

      belongs_to :spatial_ref_sys,
        foreign_key: :srid
    end

    def readonly?
      true
    end
  end
end

