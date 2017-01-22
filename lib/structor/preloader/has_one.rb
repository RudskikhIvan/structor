module Structor
  class Preloader
    class HasOne < SingularAssociation #:nodoc:
      def association_key_name
        reflection.foreign_key
      end

      def owner_key_name
        reflection.active_record_primary_key
      end

      def required_columns
        [association_key_name]
      end
    end
  end
end