
module ActiveRecordSpatial
  POSTGIS = begin
    if (version_string = ::ActiveRecord::Base.connection.select_rows('SELECT postgis_full_version()').flatten.first).present?
      hash = {
        use_stats: version_string =~ /USE_STATS/
      }

      {
        lib: /POSTGIS="([^"]+)"/,
        geos: /GEOS="([^"]+)"/,
        proj: /PROJ="([^"]+)"/,
        libxml: /LIBXML="([^"]+)"/
      }.each do |k, v|
        hash[k] = version_string.scan(v).flatten.first
      end

      hash.freeze
    else
      {}.freeze
    end
  end
end
