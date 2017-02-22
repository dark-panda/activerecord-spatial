
module ActiveRecord
  module Type
    class Geometry < Value
      def type
        :geometry
      end
    end

    class Geography < Value
      def type
        :geography
      end
    end
  end

  module ConnectionAdapters
    module PostgreSQL
      module OID
        class Geometry < Type::Geometry
        end

        class Geography < Type::Geography
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES.merge!(
  geometry: {
    name: 'geometry'
  },

  geography: {
    name: 'geography'
  }
)

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  prepend(Module.new do
    def initialize_type_map(type_map)
      super
      type_map.register_type 'geometry', ::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Geometry.new
      type_map.register_type 'geography', ::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Geography.new
    end
  end)
end
