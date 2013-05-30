
require 'activerecord-spatial/associations/base'

if ActiveRecord::VERSION::MAJOR <= 3
  require 'activerecord-spatial/associations/active_record_3'
else
  require 'activerecord-spatial/associations/active_record'
end

module ActiveRecord
  class Base #:nodoc:
    include ActiveRecordSpatial::Associations
  end
end
