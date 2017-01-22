module Structor
  class Performer
    attr_reader :relation, :options

    delegate :klass, :arel_attribute, :bound_attributes, to: :relation

    def initialize(relation, options = {})
      @relation = relation
      @options = options
    end

    def as_hashes
      result_to_hashes( load_result )
    end

    def as_structs
      result_to_structs( load_result )
    end

    private

    def load_result
      column_names = prepare_column_names

      relation = self.relation.spawn
      if column_names.present?
        relation.select_values = column_names.map { |cn|
          klass.has_attribute?(cn) || klass.attribute_alias?(cn) ? arel_attribute(cn) : cn
        }
      end
      klass.connection.select_all(relation.arel, nil, bound_attributes)
    end

    def prepare_column_names
      column_names = nil
      if only = options[:only]
        column_names = Array(only).map(&:to_s)
      elsif except = options[:except]
        column_names = klass.columns.map(&:name) - Array(except).map(&:to_s)
      end
      if options[:include].present? and column_names.present?
        Array.wrap(options[:include]).each do |accotiation|
          key = accotiation.is_a?(Hash) ? accotiation.keys.first : accotiation
          reflection = klass.reflect_on_association(key.to_sym)
          if reflection.macro == :belongs_to
            column_names << reflection.foreign_key
          else
            column_names << reflection.active_record_primary_key
          end
        end
      end
      if column_names.present? and options[:required_columns].present?
        column_names.concat(options[:required_columns])
      end
      column_names ? column_names.uniq : nil
    end

    def result_to_hashes(result)
      hashes = result.to_hash.each do |hash|
        hash.each do |k,v|
          type = result.send(:column_type, k, klass.attribute_types)
          hash[k] = type.deserialize(v)
        end
      end
      apply_includes(hashes) if options[:include].present?
      apply_methods(hashes) if options[:methods].present?
      apply_procs(hashes) if options[:procs].present?
      hashes
    end

    def result_to_structs(result)
      struct = struct_class(result)
      structs = result.cast_values(klass.attribute_types).map{|attrs| struct.new(*attrs)}
      apply_includes(structs) if options[:include].present?
      apply_methods(structs) if options[:methods].present?
      apply_procs(structs) if options[:procs].present?
      structs
    end

    def struct_class(result)
      columns = result.columns
      columns += options[:methods] if options[:methods].present?
      columns += options[:procs].keys if options[:procs].present?
      if options[:include].present?
        columns += Array.wrap(options[:include]).map{|assoc| assoc.is_a?(Hash) ? assoc.keys.first : assoc}
      end
      Struct.new(*columns.map(&:to_sym).uniq)
    end

    def apply_methods(items)
      options[:methods].each do |method|
        items.each{|item| item[method] = klass.send(method, item)}
      end
    end

    def apply_procs(items)
      options[:procs].each do |key, method|
        items.each{|item| item[key.to_s] = method.call(item)}
      end
    end

    def apply_includes(items)
      Preloader.new(klass, options[:include], items).preload
    end
  end
end