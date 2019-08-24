# frozen_string_literal: true

require 'activerecord-spatial/associations/base'
require 'activerecord-spatial/associations/reflection/spatial_reflection'
require 'activerecord-spatial/associations/preloader/spatial_association'
require 'activerecord-spatial/associations/active_record'

module ActiveRecordSpatial::Associations
  module ClassMethods #:nodoc:
    def has_many_spatially(name, scope = nil, options = {}, &extension)
      if scope.is_a?(Hash)
        options = scope
        scope   = nil
      end

      options = build_options(options)

      unless ActiveRecordSpatial::SpatialScopeConstants::RELATIONSHIPS.include?(options[:relationship].to_s)
        raise ArgumentError, %{Invalid spatial relationship "#{options[:relationship]}", expected one of #{ActiveRecordSpatial::SpatialScopeConstants::RELATIONSHIPS.inspect}}
      end

      reflection = ActiveRecord::Associations::Builder::Spatial.build(self, name, scope, options, &extension)

      if ActiveRecord::Reflection.respond_to?(:add_reflection)
        ActiveRecord::Reflection.add_reflection(self, name, reflection)
      end

      reflection
    end
  end
end

module ActiveRecord
  class Base #:nodoc:
    include ActiveRecordSpatial::Associations
  end
end
