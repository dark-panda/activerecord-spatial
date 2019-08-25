# frozen_string_literal: true

module ActiveRecordSpatial
  class SpatialFunction
    DEFAULT_OPTIONS = {
      column: ActiveRecordSpatial.default_column_name,
      use_index: true
    }.freeze

    def initialize(klass)
      @klass = klass
    end

    def self.build!(klass, *args)
      new(klass).build_function_call(*args)
    end

    def build_function_call(function, *args)
      options = default_options(args.extract_options!)

      geom = options.fetch(:geom_arg, args.first)
      args = Array.wrap(options.fetch(:args, args.from(1))).collect do |arg|
        arel_quoted_value(arg)
      end

      column_name = column_name(options[:column])
      first_geom_arg = wrap_column_or_geometry(
        @klass.arel_table[column_name],
        options[:column]
      )
      geom_args = [first_geom_arg]

      if geom.present?
        column_type = @klass.spatial_column_by_name(column_name).spatial_type
        column_srid = @klass.srid_for(column_name)

        if !geom.is_a?(Hash)
          geom_arg = read_geos(geom, column_srid)
          geom_srid = read_geom_srid(geom_arg, column_type)
          geom_args << set_srid_or_transform(column_srid, geom_srid, geom_arg, column_type)
        else
          klass = if geom[:class]
            geom[:class]
          elsif geom[:class_name]
            geom[:class_name].classify.constantize
          else
            raise ArgumentError, 'Need either a :class or :class_name option to determine the class.'
          end

          if geom[:value]
            geom_arg = read_geos(geom[:value], column_srid)
            geom_srid = read_geom_srid(geom_arg, column_type)
          else
            geom_arg = geom
            geom_srid = klass.srid_for(column_name(geom[:column]))
          end

          transformed_geom = set_srid_or_transform(column_srid, geom_srid, geom_arg, column_type)
          geom_args << wrap_column_or_geometry(transformed_geom, geom)
        end
      end

      geom_args.reverse! if options[:invert] && geom_args.length > 1

      ret = Arel::Nodes::NamedFunction.new(
        function_name(function, options[:use_index]),
        geom_args + args
      )

      ret = ret.or(first_geom_arg.eq(nil)) if options[:allow_null]

      ret
    end

    class << self
      def additional_ordering(*args)
        options = args.extract_options!

        desc = if args.first == :desc
          true
        else
          options[:desc]
        end

        ''.dup.tap do |ret|
          ret << ' DESC' if desc
          ret << " NULLS #{options[:nulls].to_s.upcase}" if options[:nulls]
        end
      end
    end

    private

      def set_srid_or_transform(column_srid, geom_srid, geom, type)
        geom_param = case geom
          when Geos::Geometry
            Arel.sql("#{@klass.connection.quote(geom.to_ewkb)}::geometry")
          when Hash
            table_name = if geom[:table_alias]
              @klass.connection.quote_table_name(geom[:table_alias])
            elsif geom[:class]
              geom[:class].quoted_table_name
            elsif geom[:class_name]
              geom[:class_name].classify.constantize.quoted_table_name
            end

            Arel.sql("#{table_name}.#{@klass.connection.quote_table_name(column_name(geom[:column]))}")
          else
            raise ArgumentError, 'Expected either a Geos::Geometry or a Hash.'
        end

        if column_srid != geom_srid
          if column_srid == ActiveRecordSpatial::UNKNOWN_SRIDS[type] || geom_srid == ActiveRecordSpatial::UNKNOWN_SRIDS[type]
            Arel::Nodes::NamedFunction.new(
              function_name('SetSRID'),
              [geom_param, column_srid]
            )

          else
            Arel::Nodes::NamedFunction.new(
              function_name('Transform'),
              [geom_param, column_srid]
            )
          end
        else
          geom_param
        end
      end

      def read_geos(geom, column_srid)
        if geom.is_a?(String) && geom =~ /^SRID=default;/
          geom = geom.sub(/default/, column_srid.to_s)
        end
        Geos.read(geom)
      end

      def read_geom_srid(geos, column_type = :geometry)
        if geos.srid.zero? || geos.srid == -1
          ActiveRecordSpatial::UNKNOWN_SRIDS[column_type]
        else
          geos.srid
        end
      end

      def default_options(*args)
        options = args.extract_options!

        if args.length.positive?
          desc = if args.first == :desc
            true
          else
            options[:desc]
          end

          DEFAULT_OPTIONS.merge(
            desc: desc
          ).merge(options || {})
        else
          DEFAULT_OPTIONS.merge(options || {})
        end
      end

      def function_name(function, use_index = true)
        if use_index
          "ST_#{function}"
        else
          "_ST_#{function}"
        end
      end

      def column_name(column_name_or_options)
        column_name = if column_name_or_options.is_a?(Hash)
          column_name_or_options[:name]
        else
          column_name_or_options
        end

        column_name || ActiveRecordSpatial.default_column_name
      end

      def wrap_column_or_geometry(column_name_or_geometry, options = nil)
        if options.is_a?(Hash) && options[:wrapper]
          wrapper, args = if options[:wrapper].is_a?(Hash)
            [options[:wrapper].keys.first, Array.wrap(options[:wrapper].values.first)]
          else
            [options[:wrapper], []]
          end

          Arel::Nodes::NamedFunction.new(
            function_name(wrapper),
            [column_name_or_geometry, *args.collect { |arg| arel_quoted_value(arg) }]
          )
        else
          column_name_or_geometry
        end
      end

      def arel_nodes_quoted?
        if defined?(@arel_nodes_quoted)
          @arel_nodes_quoted
        else
          @arel_nodes_quoted = defined?(Arel::Nodes::Quoted)
        end
      end

      def arel_quoted_value(value)
        if arel_nodes_quoted?
          Arel::Nodes::Quoted.new(value)
        else
          value
        end
      end
  end
end
