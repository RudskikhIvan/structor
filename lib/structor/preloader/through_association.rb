module Structor
  class Preloader
    class ThroughAssociation < Association

      # def initialize(reflection, owners, options = {})
      #   super reflection, owners, options
      #   include_option = options.delete(:includes) || nil
      #   @options[:include] = include_option ? {"#{source_reflection.name}": include_option} : source_reflection.name
      # end

      def through_reflection
        reflection.through_reflection
      end

      def through_scope
        through_reflection.scope_for(through_reflection.klass)
      end

      def source_reflection
        reflection.source_reflection
      end

      def middle_records
        @middle_records ||= through_scope
          .where(middle_owner_key_name => owner_keys)
          .where.not(middle_key_name => nil)
          .distinct
          .as_hashes(only: [through_reflection.foreign_key.to_sym, middle_key_name.to_sym])
      end

      def owner_key_name
        through_reflection.active_record_primary_key
      end

      def association_key_name
        source_reflection.active_record_primary_key
      end

      def middle_owner_key_name
        through_reflection.foreign_key
      end

      def middle_key_name
        source_reflection.foreign_key
      end

      def middle_keys
        @middle_keys ||= middle_records.map{|middle| middle[middle_key_name]}.tap(&:uniq!).tap(&:compact!)
      end

      def middle_key_type
        through_reflection.klass.type_for_attribute(middle_key_name).type
      end

      def middle_owner_key_type
        through_reflection.klass.type_for_attribute(middle_owner_key_name).type
      end

      def required_columns
        [association_key_name]
      end

      def load_records
        return {} if middle_keys.empty?
        # Some databases impose a limit on the number of ids in a list (in Oracle it's 1000)
        # Make several smaller queries if necessary or make one query if the adapter supports it
        slices = middle_keys.each_slice(klass.connection.in_clause_length || middle_keys.size)
        @preloaded_records = slices.flat_map do |slice|
          records_for(slice)
        end
        middle_group = middle_records.each_with_object({}) do |record, st|
          (st[convert_key(record[middle_key_name])] ||= []) << convert_key(record[middle_owner_key_name])
        end
        @preloaded_records.each_with_object({}) do |record, st|
          next unless (owner_ids = middle_group[record[convert_key(association_key_name)]])
          owner_ids.each do |owner_id|
            (st[owner_id] ||= []) << record
          end
        end
      end

      def key_conversion_required?
        @key_conversion_required ||=
            [association_key_type, owner_key_type, middle_owner_key_type, middle_key_type].uniq!.size > 1
      end

      #   through_records = owners.map do |owner|
      #     association = owner.association through_reflection.name
      #
      #     center = target_records_from_association(association)
      #     [owner, Array(center)]
      #   end
      #
      #   reset_association owners, through_reflection.name
      #
      #   middle_records = through_records.flat_map { |(_, rec)| rec }
      #
      #   preloaders = preloader.preload(middle_records,
      #                                  source_reflection.name,
      #                                  reflection_scope)
      #
      #   @preloaded_records = preloaders.flat_map(&:preloaded_records)
      #
      #   middle_to_pl = preloaders.each_with_object({}) do |pl, h|
      #     pl.owners.each { |middle|
      #       h[middle] = pl
      #     }
      #   end
      #
      #   through_records.each_with_object({}) do |(lhs, center), records_by_owner|
      #     pl_to_middle = center.group_by { |record| middle_to_pl[record] }
      #
      #     records_by_owner[lhs] = pl_to_middle.flat_map do |pl, middles|
      #       rhs_records = middles.flat_map { |r|
      #         association = r.association source_reflection.name
      #
      #         target_records_from_association(association)
      #       }.compact
      #
      #       # Respect the order on `reflection_scope` if it exists, else use the natural order.
      #       if reflection_scope.values[:order].present?
      #         @id_map ||= id_to_index_map @preloaded_records
      #         rhs_records.sort_by { |rhs| @id_map[rhs] }
      #       else
      #         rhs_records
      #       end
      #     end
      #   end
      # end

    end
  end
end
