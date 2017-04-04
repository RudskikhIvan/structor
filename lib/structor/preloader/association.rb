module Structor
  class Preloader
    class Association

      attr_reader :owners, :reflection, :options
      delegate to: :reflection

      def initialize(reflection, owners, options = {})
        @owners        = owners
        @reflection    = reflection
        @options       = options
      end

      def klass
        options[:klass] || reflection.klass
      end

      def run(preloader)
        preload(preloader)
      end

      def preload(preloader)
        raise NotImplementedError
      end

      def scope
        @scope ||= build_scope
      end

      def owner_key_name
        raise NotImplementedError
      end

      def records_for(ids)
        method = options[:convert_to] == :struct ? :as_structs : :as_hashes
        scope.where(association_key_name => ids).send(method, options.merge(required_columns: required_columns))
      end

      # The name of the key on the associated records
      def association_key_name
        raise NotImplementedError
      end

      def required_columns
        raise NotImplementedError
      end

      private

      def model
        reflection.active_record
      end

      def reflection_options
        reflection.options
      end

      def associated_records_by_owner(preloader)
        records = load_records
        owners.each_with_object({}) do |owner, result|
          result[owner] = records.present? ? (records[convert_key(owner[owner_key_name])] || []) : []
        end
      end

      def owner_keys
        @owner_keys ||= owners.map{|owner| owner[owner_key_name]}.tap(&:uniq!).tap(&:compact!)
      end

      def owners_by_key
        unless defined?(@owners_by_key)
          @owners_by_key = owners.each_with_object({}) do |owner, h|
            h[convert_key(owner[owner_key_name])] = owner
          end
        end
        @owners_by_key
      end

      def key_conversion_required?
        @key_conversion_required ||= association_key_type != owner_key_type
      end

      def convert_key(key)
        if key_conversion_required?
          key.to_s
        else
          key
        end
      end

      def load_records
        return {} if owner_keys.empty?
        # Some databases impose a limit on the number of ids in a list (in Oracle it's 1000)
        # Make several smaller queries if necessary or make one query if the adapter supports it
        slices = owner_keys.each_slice(klass.connection.in_clause_length || owner_keys.size)
        @preloaded_records = slices.flat_map do |slice|
          records_for(slice)
        end
        @preloaded_records.group_by do |record|
          convert_key(record[association_key_name])
        end
      end

      def reflection_scope
        @reflection_scope ||= reflection.scope_for(klass)
      end

      def build_scope
        scope = klass.unscoped

        values = reflection_scope.values

        scope.where_clause = reflection_scope.where_clause
        scope.references_values = Array(values[:references])
        scope.joins!(reflection_scope.joins_values)

        if order_values = values[:order]
          scope.order!(order_values)
        end

        if values[:reordering]
          scope.reordering_value = true
        end

        if values[:readonly]
          scope.readonly!
        end

        if reflection_options[:as]
          scope.where!(klass.table_name => { reflection.type => model.base_class.sti_name })
        end

        scope.unscope_values = Array(values[:unscope])
        klass.default_scoped.merge(scope)
      end

      def association_key_type
        klass.type_for_attribute(association_key_name.to_s).type
      end

      def owner_key_type
        reflection.active_record.type_for_attribute(owner_key_name.to_s).type
      end

    end
  end
end