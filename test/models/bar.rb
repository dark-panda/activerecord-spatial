# frozen_string_literal: true

class Bar < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  create_spatial_column_accessors!
end
