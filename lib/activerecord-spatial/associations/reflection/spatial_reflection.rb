
module ActiveRecord
  module Reflection #:nodoc:
    SPATIAL_REFLECTION_BASE_CLASS = if ActiveRecord::VERSION::STRING >= '4.2'
      HasManyReflection
    else
      AssociationReflection
    end

    class SpatialReflection < SPATIAL_REFLECTION_BASE_CLASS #:nodoc:
      attr_reader :geom, :foreign_geom, :relationship, :scope_options

      def initialize(*args)
        if ActiveRecord::VERSION::STRING >= '4.2'
          super(*args.from(1))
        else
          super
        end

        @geom = options[:geom]
        @foreign_geom = options[:foreign_geom]
        @relationship = options[:relationship].to_s
        @scope_options = (options[:scope_options] || {}).merge(column: foreign_geom)
      end

      def association_class
        Associations::SpatialAssociation
      end
    end

    if ActiveRecord::Reflection.respond_to?(:create)
      class << self
        def create_with_spatial(macro, name, scope, options, ar)
          if options[:relationship] && options[:geom] && options[:foreign_geom]
            SpatialReflection.new(macro, name, scope, options, ar)
          else
            create_without_spatial(macro, name, scope, options, ar)
          end
        end
        alias_method_chain :create, :spatial
      end
    else
      module ClassMethods
        def create_reflection_with_spatial(macro, name, scope, options, ar)
          if options[:relationship] && options[:geom] && options[:foreign_geom]
            reflection = SpatialReflection.new(macro, name, scope, options, ar)
            self.reflections = self.reflections.merge(name => reflection)
            reflection
          else
            create_reflection_without_spatial(macro, name, scope, options, ar)
          end
        end
        alias_method_chain :create_reflection, :spatial
      end
    end
  end
end

