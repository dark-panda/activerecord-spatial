# frozen_string_literal: true

module ActiveRecord
  module Associations #:nodoc:
    class SpatialAssociationScope < AssociationScope #:nodoc:
      INSTANCE = create

      class << self
        def scope(association)
          ActiveRecord::Associations::SpatialAssociationScope::INSTANCE.scope(association)
        end

        def get_bind_values(owner, chain)
          binds = []
          last_reflection = chain.last

          if last_reflection.type
            binds << owner.class.polymorphic_name
          end

          chain.each_cons(2).each do |reflection, next_reflection|
            if reflection.type
              binds << next_reflection.klass.polymorphic_name
            end
          end
          binds
        end
      end

      def last_chain_scope(scope, reflection, owner)
        geom_options = {
          class: reflection.klass
        }

        if reflection.geom.is_a?(Hash)
          geom_options[:value] = owner[reflection.geom[:name]]
          geom_options.merge!(reflection.geom)
        else
          geom_options[:value] = owner[reflection.geom]
          geom_options[:name] = reflection.geom
        end

        join_keys = reflection.join_keys
        table = reflection.aliased_table

        scope = scope.send("st_#{reflection.relationship}", geom_options, reflection.scope_options)

        if reflection.type
          polymorphic_type = transform_value(owner.class.polymorphic_name)
          scope = apply_scope(scope, table, reflection.type, polymorphic_type)
        end

        scope
      end
    end

    class Preloader #:nodoc:
      class SpatialAssociation < Association #:nodoc:
        SPATIAL_FIELD_ALIAS = '__spatial_ids__'
        SPATIAL_JOIN_NAME = '__spatial_ids_join__'
        SPATIAL_JOIN_QUOTED_NAME = %{"#{SPATIAL_JOIN_NAME}"}

        private

          def records_for(ids)
            join_name = reflection.active_record.quoted_table_name
            column = %{#{SPATIAL_JOIN_QUOTED_NAME}.#{klass.quoted_primary_key}}
            geom = {
              class: reflection.active_record,
              table_alias: SPATIAL_JOIN_NAME
            }

            if reflection.options[:geom].is_a?(Hash)
              geom.merge!(reflection.options[:geom])
            else
              geom[:column] = reflection.options[:geom]
            end

            where_function = klass.send(
              "st_#{reflection.options[:relationship]}",
              geom,
              (reflection.options[:scope_options] || {}).merge(
                column: reflection.options[:foreign_geom]
              )
            )

            spatial_scope = scope
              .select(%{#{klass.quoted_table_name}.*, array_to_string(array_agg(#{column}), ',') AS "#{SPATIAL_FIELD_ALIAS}"})
              .joins(
                "INNER JOIN #{join_name} AS #{SPATIAL_JOIN_QUOTED_NAME} ON (" +
                  where_function.where_clause.send(:predicates).join(' AND ') +
                  ')'
              )
              .where(klass.arel_table.alias(SPATIAL_JOIN_NAME)[klass.primary_key].in(ids))
              .group(klass.arel_table[klass.primary_key])

            spatial_scope.load do |record|
              record[SPATIAL_FIELD_ALIAS].split(',').each do |spatial_id|
                owner = owners_by_key[convert_key(spatial_id)].first

                association = owner.association(reflection.name)
                association.set_inverse_instance(record)
              end
            end
          end

          def records_by_owner
            @records_by_owner ||= preloaded_records.each_with_object({}.compare_by_identity) do |record, result|
              record[SPATIAL_FIELD_ALIAS].split(',').each do |spatial_id|
                owners_by_key[convert_key(spatial_id)].each do |owner|
                  (result[owner] ||= []) << record
                end
              end
            end
          end
      end

      private

        prepend(Module.new do
          def preloader_for(reflection, owners)
            return super unless reflection.is_a?(ActiveRecord::Reflection::SpatialReflection)
            return AlreadyLoaded if owners.first.association(reflection.name).loaded?

            reflection.check_preloadable!

            SpatialAssociation
          end
      end)
    end
  end
end
