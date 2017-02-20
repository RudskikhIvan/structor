require "structor/performer"
require "structor/preloader"

module Structor
  module ActiveRecordQueringExtension
    delegate :as_hashes, :as_structs, to: :all
  end

  module ActiveRecordScopeExtension
    def as_hashes(options = {})
      Structor::Performer.new(self, {convert_to: :hash}.merge(options)).load
    end

    def as_structs(options = {})
      Structor::Performer.new(self, {convert_to: :struct}.merge(options)).load
    end
  end
end

ActiveRecord::Relation.send :include, Structor::ActiveRecordScopeExtension
ActiveRecord::Base.send :extend, Structor::ActiveRecordQueringExtension