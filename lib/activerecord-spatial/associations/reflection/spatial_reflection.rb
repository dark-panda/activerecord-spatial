
module ActiveRecord
  module Reflection #:nodoc:
    SPATIAL_REFLECTION_BASE_CLASS = HasManyReflection

    module RuntimeReflectionWithSpatialReflection
      delegate :geom, :relationship, :scope_options, to: :@reflection
    end

    RuntimeReflection.prepend RuntimeReflectionWithSpatialReflection

    class SpatialReflection < SPATIAL_REFLECTION_BASE_CLASS #:nodoc:
      attr_reader :geom, :foreign_geom, :relationship, :scope_options

      def initialize(*args)
        super(*args.from(1))

        @geom = options[:geom]
        @foreign_geom = options[:foreign_geom]
        @relationship = options[:relationship].to_s
        @scope_options = (options[:scope_options] || {}).merge(column: foreign_geom)
      end

      def association_class
        Associations::SpatialAssociation
      end
    end

    class << self
      prepend(Module.new do
        def create(macro, name, scope, options, ar)
          if options[:relationship] && options[:geom] && options[:foreign_geom]
            SpatialReflection.new(macro, name, scope, options, ar)
          else
            super
          end
        end
      end)
    end
  end
end
