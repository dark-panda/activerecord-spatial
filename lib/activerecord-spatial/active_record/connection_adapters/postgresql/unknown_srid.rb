
module ActiveRecordSpatial
  UNKNOWN_SRIDS = begin
    if ActiveRecordSpatial::POSTGIS[:lib] >= '2.0'
      {
        geography: 0,
        geometry: 0
      }.freeze
    else
      {
        geography:  0,
        geometry: -1
      }.freeze
    end
  end

  UNKNOWN_SRID = begin
    ActiveRecordSpatial::UNKNOWN_SRIDS[:geometry]
  end
end

