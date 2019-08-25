# frozen_string_literal: true

class FooGeography < ActiveRecord::Base
  include ActiveRecordSpatial::SpatialColumns
  include ActiveRecordSpatial::SpatialScopes

  create_spatial_column_accessors!
end
