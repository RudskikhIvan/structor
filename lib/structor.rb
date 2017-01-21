require "structor/performer"

module Structor
  module ActiveRecordQueringExtension
    delegate :as_hashes, :as_structs, to: :all
  end

  module ActiveRecordScopeExtension
    def as_hashes(options = {})
      Structor::Performer.new(self, options).as_hashes
    end

    def as_structs(options = {})
      Structor::Performer.new(self, options).as_structs
    end
  end
end

ActiveRecord::Relation.send :include, Structor::ActiveRecordScopeExtension
ActiveRecord::Base.send :extend, Structor::ActiveRecordQueringExtension