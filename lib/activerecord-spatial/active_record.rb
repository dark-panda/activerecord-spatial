
module ActiveRecordSpatial
  autoload :SpatialFunction, 'activerecord-spatial/spatial_function'
  autoload :SpatialColumns, 'activerecord-spatial/spatial_columns'
  autoload :SpatialScopeConstants, 'activerecord-spatial/spatial_scope_constants'
  autoload :SpatialScopes, 'activerecord-spatial/spatial_scopes'
  autoload :SpatialColumn, 'activerecord-spatial/active_record/models/spatial_column'
  autoload :SpatialRefSys, 'activerecord-spatial/active_record/models/spatial_ref_sys'
  autoload :GeometryColumn, 'activerecord-spatial/active_record/models/geometry_column'
  autoload :GeographyColumn, 'activerecord-spatial/active_record/models/geography_column'
end

require 'activerecord-spatial/associations'
