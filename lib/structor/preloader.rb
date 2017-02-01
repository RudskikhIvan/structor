module Structor
  class Preloader
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Association
      autoload :SingularAssociation
      autoload :CollectionAssociation
      autoload :ThroughAssociation

      autoload :HasMany
      autoload :HasManyThrough
      autoload :HasOne
      autoload :HasOneThrough
      autoload :BelongsTo
    end

    attr_reader :owners, :associations, :klass

    def initialize(klass, associations, owners)
      @owners =  Array.wrap(owners).compact.uniq
      @associations = Array.wrap(associations)
      @klass = klass
    end

    def preload
      if @owners.empty?
        []
      else
        @associations.flat_map { |association|
          preloaders_on association
        }
      end
    end

    def self.preload(klass, associations, owners)
      self.new(klass, associations, owners).preload
    end

    private


    def preloaders_on(association)
      case association
        when Hash
          preloaders_for_hash(association)
        when Symbol
          preloaders_for_one(association)
        when String
          preloaders_for_one(association.to_sym)
        else
          raise ArgumentError, "#{association.inspect} was not recognized for preload"
      end
    end

    def preloaders_for_hash(association)
      association.flat_map { |assoc, options|
        preloaders_for_one assoc, options
      }
    end

    def preloaders_for_one(association, options = {})
      reflection = klass._reflect_on_association(association)
      preloader = preloader_for(reflection).new(reflection, owners, options)
      preloader.run(self)
    end

    def preloader_for(reflection)
      case reflection.macro
        when :has_many
          reflection.options[:through] ? HasManyThrough : HasMany
        when :has_one
          reflection.options[:through] ? HasOneThrough : HasOne
        when :belongs_to
          BelongsTo
      end
    end

  end
end