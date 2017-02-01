module Structor
  class Preloader
    class HasManyThrough < ThroughAssociation #:nodoc:

      private

      def preload(preloader)
        associated_records_by_owner(preloader).each do |owner, records|
          owner[reflection.name.to_s] = records
        end
      end

    end
  end
end