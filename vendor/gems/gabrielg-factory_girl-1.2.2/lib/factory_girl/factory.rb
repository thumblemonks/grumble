class Factory

  cattr_accessor :factories #:nodoc:
  self.factories = {}

  # An Array of strings specifying locations that should be searched for
  # factory definitions. By default, factory_girl will attempt to require
  # "factories," "test/factories," and "spec/factories." Only the first
  # existing file will be loaded.
  cattr_accessor :definition_file_paths
  self.definition_file_paths = %w(factories test/factories spec/factories)

  attr_reader :factory_name, :inherited_factory

  # Defines a new factory that can be used by the build strategies (create and
  # build) to build new objects.
  #
  # Arguments:
  #   name: (Symbol)
  #     A unique name used to identify this factory.
  #   options: (Hash)
  #     class: the class that will be used when generating instances for this
  #            factory. If not specified, the class will be guessed from the
  #            factory name.
  #
  # Yields:
  #    The newly created factory (Factory)
  def self.define (name, options = {})
    inherit_from = options.delete(:inherit)
    options = inherit_from ? options.merge(:inherit => factories[inherit_from]) : options
    raise(ArgumentError, "Inherited factory not defined") if inherit_from && options[:inherit].blank?
    instance = Factory.new(name, options)
    yield(instance)
    self.factories[instance.factory_name] = instance
  end

  def build_class #:nodoc:
    @build_class ||= class_for(@options[:class] || factory_name)
  end

  def initialize (name, options = {}) #:nodoc:
    options.assert_valid_keys(:class, :inherit)
    @factory_name = factory_name_for(name)
    @options      = options
    @attributes   = []
    @static_attributes     = {}
    @lazy_attribute_blocks = {}
    @lazy_attribute_names  = []
    @callbacks = {}
    @inherited_factory = options[:inherit]
    @options[:class] = inherited_factory.build_class if inherited_factory && !@options.has_key?(:class)
  end

  # Adds an attribute that should be assigned on generated instances for this
  # factory.
  #
  # This method should be called with either a value or block, but not both. If
  # called with a block, the attribute will be generated "lazily," whenever an
  # instance is generated. Lazy attribute blocks will not be called if that
  # attribute is overriden for a specific instance.
  #
  # When defining lazy attributes, an instance of Factory::AttributeProxy will
  # be yielded, allowing associations to be built using the correct build
  # strategy.
  #
  # Arguments:
  #   name: (Symbol)
  #     The name of this attribute. This will be assigned using :"#{name}=" for
  #     generated instances.
  #   value: (Object)
  #     If no block is given, this value will be used for this attribute.
  def add_attribute (name, value = nil, &block)
    attribute = Attribute.new(name, value, block)

    if attribute_defined?(attribute.name)
      raise AttributeDefinitionError, "Attribute already defined: #{name}"
    end

    @attributes << attribute
  end

  # Adds an anonymous sequence for an attribute:
  #
  #   Factory.define :user do |f|
  #     f.sequence do |n|
  #       "Johnny #{n}"
  #     end
  #   end
  #
  # When generating an instance, the next value in the sequence will be used.
  def sequence (name, &proc)
    sequence = Sequence.new(&proc)
    add_attribute(name) do
      sequence.next
    end
  end

  # Calls add_attribute using the missing method name as the name of the
  # attribute, so that:
  #
  #   Factory.define :user do |f|
  #     f.name 'Billy Idol'
  #   end
  #
  # and:
  #
  #   Factory.define :user do |f|
  #     f.add_attribute :name, 'Billy Idol'
  #   end
  #
  # are equivilent.
  def method_missing (name, *args, &block)
    add_attribute(name, *args, &block)
  end

  # Adds an attribute that builds an association. The associated instance will
  # be built using the same build strategy as the parent instance.
  #
  # Example:
  #   Factory.define :user do |f|
  #     f.name 'Joey'
  #   end
  #
  #   Factory.define :post do |f|
  #     f.association :author, :factory => :user
  #   end
  #
  # Arguments:
  #   name: (Symbol)
  #     The name of this attribute.
  #   options: (Hash)
  #     factory: (Symbol)
  #       The name of the factory to use when building the associated instance.
  #       If no name is given, the name of the attribute is assumed to be the
  #       name of the factory. For example, a "user" association will by
  #       default use the "user" factory.
  def association (name, options = {})
    name    = name.to_sym
    options = options.symbolize_keys
    association_factory = (options[:count] ? (options[:factory] || name.to_s.singularize) : (options[:factory] || name)).to_sym

    add_attribute(name) { |a| a.association(association_factory, {}, {:count => options[:count]}) }
  end

  def attributes_for (attrs = {}, strategy_override = :attributes_for) #:nodoc:
    build_attributes_hash(attrs, strategy_override)
  end

  def build (attrs = {}) #:nodoc:
    build_instance(attrs, :build).first
  end

  def create (attrs = {}) #:nodoc:
    instance, final_attrs = build_instance(attrs, :create)
    instance.save!
    if callback = @callbacks[:after_create]
      params = (callback.arity > 1) ? [instance, final_attrs] : [instance]
      callback.call(*params)
    end
    instance
  end

  # Allows a block to be evaluated after the factory object has been built, but before
  # it is saved to the database.  The block is passed the instance so you can do stuff
  # to it. For example, maybe you want to stub a method whose result normally relies on
  # complex computation on attributes and associations:
  #
  #   Factory.define :a_boy_that_never_goes_out, :class => Boy do |f|
  #     f.name 'Morrisey'
  #     f.after_build do |b|
  #       b.stubs(:goes_out).returns(false)
  #     end
  #   end
  def after_build(&block)
    @callbacks[:after_build] = block
  end

  # Allows a block to be evaluated after the factory object has been saved to the
  # database.  The block is passed the instance so you can do stuff to it. For example
  # maybe you want to stub a method whose result normally relies on complex computation
  # on attributes and associations:
  #
  #   Factory.define :a_boy_that_never_goes_out, :class => Boy do |f|
  #     f.name 'Morrisey'
  #     f.after_create do |b|
  #       b.stubs(:goes_out).returns(false)
  #     end
  #   end
  def after_create(&block)
    @callbacks[:after_create] = block
  end

  class << self

    # Generates and returns a Hash of attributes from this factory. Attributes
    # can be individually overridden by passing in a Hash of attribute => value
    # pairs.
    #
    # Arguments:
    #   attrs: (Hash)
    #     Attributes to overwrite for this set.
    #
    # Returns:
    #   A set of attributes that can be used to build an instance of the class
    #   this factory generates. (Hash)
    def attributes_for (name, attrs = {})
      factory_by_name(name).attributes_for(attrs)
    end

    # Generates and returns an instance from this factory. Attributes can be
    # individually overridden by passing in a Hash of attribute => value pairs.
    #
    # Arguments:
    #   attrs: (Hash)
    #     See attributes_for
    #
    # Returns:
    #   An instance of the class this factory generates, with generated
    #   attributes assigned.
    def build (name, attrs = {})
      factory_by_name(name).build(attrs)
    end

    # Generates, saves, and returns an instance from this factory. Attributes can
    # be individually overridden by passing in a Hash of attribute => value
    # pairs.
    #
    # If the instance is not valid, an ActiveRecord::Invalid exception will be
    # raised.
    #
    # Arguments:
    #   attrs: (Hash)
    #     See attributes_for
    #
    # Returns:
    #   A saved instance of the class this factory generates, with generated
    #   attributes assigned.
    def create (name, attrs = {})
      factory_by_name(name).create(attrs)
    end

    def find_definitions #:nodoc:
      definition_file_paths.each do |path|
        begin
          require(path)
          break
        rescue LoadError
        end
      end
    end

    private

    def factory_by_name (name)
      factories[name.to_sym] or raise ArgumentError.new("No such factory: #{name.to_s}")
    end

  end

  private

  def build_attributes_hash (values, strategy)
    values = values.symbolize_keys
    passed_keys = values.keys.collect {|key| Factory.aliases_for(key) }.flatten
    attrs = @attributes.inject(values) do |vals,attribute|
      next(vals) if passed_keys.include?(attribute.name)
      proxy = AttributeProxy.new(self, attribute.name, strategy, vals)
      vals[attribute.name] = attribute.value(proxy)
      vals
    end
    inherited_factory ? inherited_factory.attributes_for(attrs, strategy) : attrs
  end

  def build_instance (override, strategy)
    instance = build_class.new
    attrs = build_attributes_hash(override, strategy)
    attrs.each do |attr, value|
      instance.send(:"#{attr}=", value) if instance.respond_to?(:"#{attr}=")
    end
    if callback = @callbacks[:after_build]
      params = (callback.arity > 1) ? [instance, attrs] : [instance]
      callback.call(*params)
    end
    [instance, attrs]
  end

  def class_for (class_or_to_s)
    if class_or_to_s.respond_to?(:to_sym)
      class_or_to_s.to_s.pluralize.classify.constantize
    else
      class_or_to_s
    end
  end

  def factory_name_for (class_or_to_s)
    if class_or_to_s.respond_to?(:to_sym)
      class_or_to_s.to_sym
    else
      class_or_to_s.to_s.underscore.to_sym
    end
  end

  def attribute_defined? (name)
    !@attributes.detect {|attr| attr.name == name }.nil?
  end

end
