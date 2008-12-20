require(File.join(File.dirname(__FILE__), 'test_helper'))

class FactoryTest < Test::Unit::TestCase

  def self.should_instantiate_class

    should "instantiate the build class" do
      assert_kind_of @class, @instance
    end

    should "assign attributes on the instance" do
      assert_equal @first_name, @instance.first_name
      assert_equal @last_name,  @instance.last_name
    end

    should "override attributes using the passed hash" do
      @value = 'Davis'
      @instance = @factory.build(:first_name => @value)
      assert_equal @value, @instance.first_name
    end

  end

  context "defining a factory" do

    setup do
      @name    = :user
      @factory = mock('factory')
      @factory.stubs(:factory_name).returns(@name)
      @options = { :class => 'magic' }
      Factory.stubs(:new).returns(@factory)
    end

    should "create a new factory using the specified name and options" do
      Factory.expects(:new).with(@name, @options).returns(@factory)
      Factory.define(@name, @options) {|f| }
    end

    should "pass the factory do the block" do
      yielded = nil
      Factory.define(@name) do |y|
        yielded = y
      end
      assert_equal @factory, yielded
    end

    should "add the factory to the list of factories" do
      Factory.define(@name) {|f| }
      assert_equal Factory.factories[@name],
                   @factory,
                   "Factories: #{Factory.factories.inspect}"
    end

  end

  context "a factory" do

    setup do
      @name    = :user
      @class   = User
      @factory = Factory.new(@name)
    end

    should "have a factory name" do
      assert_equal @name, @factory.factory_name
    end

    should "have a build class" do
      assert_equal @class, @factory.build_class
    end

    should "have a set of callbacks" do
      assert @factory.instance_eval {@callbacks}
    end

    should "have an empty set of callbacks when none have been set" do
      assert @factory.instance_eval {@callbacks.empty?}
    end

    context "when inheriting from a prior factory" do
      setup do
        @factory.foo "bar"
        @factory.snafu { "foo" }
        @new_factory = Factory.new(:user_with_stuff, :inherit => @factory)
        @new_factory.foo "fighters"
        @instance = @new_factory.build
      end

      teardown do
        Factory.factories = {}
      end

      should "use subfactory's class if not specified" do
        assert_equal User, @factory.build_class
      end

      should "allow overriding subfactory's class" do
        newer_factory = Factory.new(:user_with_more_stuff, :inherit => @new_factory, :class => Post)
        assert_equal Post, newer_factory.build_class
      end

      should "override previously configured attributes" do
        assert_equal "fighters", @instance.foo
      end

      should "inherit attributes that arent overridden" do
        assert_equal "foo", @instance.snafu
      end

      should "also inherit associations" do
        Factory.define(:user) do |u|
          u.first_name "Joe"
          u.last_name "Bloggs"
          u.email "joe@example.com"
        end

        factory = Factory.new(:post)
        factory.association(:author, :factory => :user)
        inherited = Factory.new(:post_with_stuff, :inherit => factory)
        instance = inherited.build
        assert_instance_of User, instance.author
      end

    end

    context "when defining an inheriting factory" do
      setup do
        Factory.define(:user) do |u|
          u.first_name "Joe"
          u.last_name "Bloggs"
          u.email "joe@example.com"
        end
      end

      teardown do
        Factory.factories = {}
      end

      should "pass in an instance of the inherited factory as the inherited_factory" do
        instance = Factory.define(:user_with_stuff, :inherit => :user) {}
        assert_equal Factory.factories[:user], instance.inherited_factory
      end

      should "get its own factory definition" do
        instance = Factory.define(:user_with_stuff, :inherit => :user) { }
        assert_equal instance, Factory.factories[:user_with_stuff]
      end

      should "raise if inherited factory isnt found" do
        assert_raise(ArgumentError) do
          Factory.define(:user_with_stuff, :inherit => :foobar) { }
        end
      end

    end

    context "when adding an after_build callback" do
      setup do
        @the_block = lambda{|u| }
        @factory.after_build &@the_block
      end

      should "have something in the set of callbacks" do
        assert_equal 1, @factory.instance_eval {@callbacks.size}
      end

      should "record the callback in the set of callbacks" do
        assert @factory.instance_eval {@callbacks.values}.include?(@the_block)
      end

      should "record the callback in the set of callbacks under the after_build key" do
        assert_equal @the_block, @factory.instance_eval {@callbacks[:after_build]}
      end

    end

    context "when adding an after_create callback" do
      setup do
        @the_block = lambda{|u| }
        @factory.after_create &@the_block
      end

      should "have something in the set of callbacks" do
        assert_equal 1, @factory.instance_eval {@callbacks.size}
      end

      should "record the callback in the set of callbacks" do
        assert @factory.instance_eval {@callbacks.values}.include?(@the_block)
      end

      should "record the callback in the set of callbacks under the after_create key" do
        assert_equal @the_block, @factory.instance_eval {@callbacks[:after_create]}
      end
    end

    should "not allow the same attribute to be added twice" do
      assert_raise(Factory::AttributeDefinitionError) do
        2.times { @factory.add_attribute @name }
      end
    end

    context "when adding an attribute with a value parameter" do

      setup do
        @attr  = :name
        @value = 'Elvis lives!'
        @factory.add_attribute(@attr, @value)
      end

      should "include that value in the generated attributes hash" do
        assert_equal @value, @factory.attributes_for[@attr]
      end

    end

    context "when adding a sequence attribute" do

      setup do
        @attr  = :name
      end

      should "not evaluate the block when the sequence is added" do
        @factory.sequence(@attr){ flunk }
      end

      should "call next in the sequence when attributes are generated" do
        @factory.sequence(@attr) do |n|
          "sequence #{n}"
        end
        assert_equal "sequence 1", @factory.attributes_for[@attr]
        assert_equal "sequence 2", @factory.attributes_for[@attr]
      end

    end

    context "when adding an attribute with a block" do

      setup do
        @attr  = :name
        @attrs = {}
        @proxy = mock('attr-proxy')
        Factory::AttributeProxy.stubs(:new).returns(@proxy)
      end

      should "not evaluate the block when the attribute is added" do
        @factory.add_attribute(@attr) { flunk }
      end

      should "evaluate the block when attributes are generated" do
        called = false
        @factory.add_attribute(@attr) do
          called = true
        end
        @factory.attributes_for
        assert called
      end

      should "use the result of the block as the value of the attribute" do
        value = "Watch out for snakes!"
        @factory.add_attribute(@attr) { value }
        assert_equal value, @factory.attributes_for[@attr]
      end

      should "build an attribute proxy" do
        Factory::AttributeProxy.expects(:new).with(@factory, @attr, :attributes_for, @attrs)
        @factory.add_attribute(@attr) {}
        @factory.attributes_for
      end

      should "yield an attribute proxy to the block" do
        yielded = nil
        @factory.add_attribute(@attr) {|y| yielded = y }
        @factory.attributes_for
        assert_equal @proxy, yielded
      end

      context "when other attributes have previously been defined" do

        setup do
          @attr  = :unimportant
          @attrs = {
            :one     => 'whatever',
            :another => 'soup'
          }
          @factory.add_attribute(:one, 'whatever')
          @factory.add_attribute(:another) { 'soup' }
          @factory.add_attribute(@attr) {}
        end

        should "provide previously set attributes" do
          Factory::AttributeProxy.expects(:new).with(@factory, @attr, :attributes_for, @attrs)
          @factory.attributes_for
        end

      end

    end

    context "when adding an association without a factory name" do

      setup do
        @factory = Factory.new(:post)
        @name    = :user
        @factory.association(@name)
        Post.any_instance.stubs(:user=)
      end

      should "add an attribute with the name of the association" do
        assert @factory.attributes_for.key?(@name)
      end

      should "create a block that builds the association" do
        Factory.expects(:build).with(@name, {})
        @factory.build
      end

    end

    context "when adding an association with a factory name" do

      setup do
        @factory      = Factory.new(:post)
        @name         = :author
        @factory_name = :user
        @factory.association(@name, :factory => @factory_name)
      end

      should "add an attribute with the name of the association" do
        assert @factory.attributes_for.key?(@name)
      end

      should "create a block that builds the association" do
        Factory.expects(:build).with(@factory_name, {})
        @factory.build
      end

    end

    context "specifying an association on a factory with a count" do
      setup do
        Factory.define(:post) { |f| f.name "Article" }
        Factory.define(:user) do |u|
          u.first_name "Joe"
          u.last_name "Bloggs"
          u.email "joe@example.com"
          u.association :posts, :count => 5
        end
        @user = Factory(:user)
      end

      teardown do
        Factory.factories = {}
      end

      should "set up five associated post objects" do
        assert_equal 5, @user.posts.size
      end

      should "have the user as the author on each object" do
        @user.posts.each { |p| assert_equal @user, p.author }
      end

      should "have saved all the posts" do
        @user.posts.each { |p| assert !p.new_record? }
      end

    end

    should "add an attribute using the method name when passed an undefined method" do
      @attr  = :first_name
      @value = 'Sugar'
      @factory.send(@attr, @value)
      assert_equal @value, @factory.attributes_for[@attr]
    end

    should "allow attributes to be added with strings as names" do
      @factory.add_attribute('name', 'value')
      assert_equal 'value', @factory.attributes_for[:name]
    end

    context "when overriding generated attributes with a hash" do

      setup do
        @attr  = :name
        @value = 'The price is right!'
        @hash  = { @attr => @value }
      end

      should "return the overridden value in the generated attributes" do
        @factory.add_attribute(@attr, 'The price is wrong, Bob!')
        assert_equal @value, @factory.attributes_for(@hash)[@attr]
      end

      should "not call a lazy attribute block for an overridden attribute" do
        @factory.add_attribute(@attr) { flunk }
        @factory.attributes_for(@hash)
      end

      should "override a symbol parameter with a string parameter" do
        @factory.add_attribute(@attr, 'The price is wrong, Bob!')
        @hash = { @attr.to_s => @value }
        assert_equal @value, @factory.attributes_for(@hash)[@attr]
      end

    end

    context "overriding an attribute with an alias" do

      setup do
        @factory.add_attribute(:test, 'original')
        Factory.alias(/(.*)_alias/, '\1')
        @result = @factory.attributes_for(:test_alias => 'new')
      end

      should "use the passed in value for the alias" do
        assert_equal 'new', @result[:test_alias]
      end

      should "discard the predefined value for the attribute" do
        assert_nil @result[:test]
      end

    end

    should "guess the build class from the factory name" do
      assert_equal User, @factory.build_class
    end

    context "when defined with a custom class" do

      setup do
        @class   = User
        @factory = Factory.new(:author, :class => @class)
      end

      should "use the specified class as the build class" do
        assert_equal @class, @factory.build_class
      end

    end

    context "when defined with a class instead of a name" do

      setup do
        @class   = ArgumentError
        @name    = :argument_error
        @factory = Factory.new(@class)
      end

      should "guess the name from the class" do
        assert_equal @name, @factory.factory_name
      end

      should "use the class as the build class" do
        assert_equal @class, @factory.build_class
      end

    end
    context "when defined with a custom class name" do

      setup do
        @class   = ArgumentError
        @factory = Factory.new(:author, :class => :argument_error)
      end

      should "use the specified class as the build class" do
        assert_equal @class, @factory.build_class
      end

    end

    context "with some attributes added" do

      setup do
        @first_name = 'Billy'
        @last_name  = 'Idol'
        @email      = 'test@something.com'

        @factory.add_attribute(:first_name, @first_name)
        @factory.add_attribute(:last_name,  @last_name)
        @factory.add_attribute(:email,      @email)
      end

      context "and an after_build callback has been registered" do

        setup do
          @the_block = lambda {|user| assert user.new_record?; @saved = user}
          @factory.after_build &@the_block
        end

        should "call the callback when the object is built" do
          @the_block.expects(:call)
          @factory.build
        end

        should "call the callback when the object is created" do
          @the_block.expects(:call)
          @factory.create
        end

        should "yield the instance to block if block arity is <= 1" do
          @the_block.expects(:call).with(anything)
          @factory.build
        end

        should "yield the instance and attrs to block if block arity is > 1" do
          the_block = lambda {|user,attrs|}
          @factory.after_build &the_block
          the_block.expects(:call).with(anything, instance_of(Hash))
          @factory.build
        end

        should "yield the instance to the callback when called" do
          instance = @factory.build
          assert_equal @saved, instance
        end
      end

      context "and an after_create callback has been registered" do

        setup do
          @the_block = lambda {|user| assert !user.new_record?; @saved = user}
          @factory.after_create &@the_block
        end

        should "not call the callback when the object is built" do
          @the_block.expects(:call).never
          @factory.build
        end

        should "call the callback when the object is created" do
          @the_block.expects(:call).with(anything)
          @factory.create
        end

        should "yield the instance to block if block arity is <= 1" do
          @the_block.expects(:call).with(anything)
          @factory.create
        end

        should "yield the instance and attrs to block if block arity is > 1" do
          the_block = lambda {|user,attrs|}
          @factory.after_create &the_block
          the_block.expects(:call).with(anything, instance_of(Hash))
          @factory.create
        end

        should "yield the instance to the callback when called" do
          instance = @factory.create
          assert_equal @saved, instance
        end
      end

      context "and both after_build and after_create callbacks have been registered" do

        setup do
          @the_after_build_block = lambda {|user| assert(user.new_record?); @post_build = user}
          @the_after_create_block = lambda {|user| assert(!user.new_record?); @post_create = user}

          @factory.after_build &@the_after_build_block
          @factory.after_create &@the_after_create_block
        end

        should "only call the after_build callback when the object is built" do
          @the_after_build_block.expects(:call).once
          @factory.build
        end

        should "call both callbacks when the object is created" do
          @the_after_build_block.expects(:call).once
          @the_after_create_block.expects(:call).once
          @factory.create
        end

        should "yield the same instance to each callback when called" do
          instance = @factory.create
          assert_equal @post_build, instance
          assert_equal @post_create, instance
          assert_equal @post_create, @post_build
        end

        should "call the after_build callback before the after_create callback when objects are created" do
          # TODO - is this good enough to detect "beforeness"?
          @the_after_build_block = lambda {|user| assert_nil @post_build; assert_nil @post_create; @post_build = user}
          @the_after_create_block = lambda {|user| assert_not_nil @post_build; assert_nil @post_create; @post_create = user}

          @factory.after_build &@the_after_build_block
          @factory.after_create &@the_after_create_block
          @factory.create
        end
      end

      context "when building an instance" do

        setup do
          @instance = @factory.build
        end

        should_instantiate_class

        should "not save the instance" do
          assert @instance.new_record?
        end

      end

      context "when creating an instance" do

        setup do
          @instance = @factory.create
        end

        should_instantiate_class

        should "save the instance" do
          assert !@instance.new_record?
        end

      end

      should "raise an ActiveRecord::RecordInvalid error for invalid instances" do
        assert_raise(ActiveRecord::RecordInvalid) do
          @factory.create(:first_name => nil)
        end
      end

    end

  end

  context "a factory with a string for a name" do

    setup do
      @name    = :user
      @factory = Factory.new(@name.to_s) {}
    end

    should "convert the string to a symbol" do
      assert_equal @name, @factory.factory_name
    end

  end

  context "a factory defined with a string name" do

    setup do
      Factory.factories = {}
      @name    = :user
      @factory = Factory.define(@name.to_s) {}
    end

    should "store the factory using a symbol" do
      assert_equal @factory, Factory.factories[@name]
    end

  end

  context "Factory class" do

    setup do
      @name       = :user
      @attrs      = { :last_name => 'Override' }
      @first_name = 'Johnny'
      @last_name  = 'Winter'
      @class      = User

      Factory.define(@name) do |u|
        u.first_name @first_name
        u.last_name  { @last_name }
        u.email      'jwinter@guitar.org'
      end

      @factory = Factory.factories[@name]
    end

    [:build, :create, :attributes_for].each do |method|

      should "delegate the #{method} method to the factory instance" do
        @factory.expects(method).with(@attrs)
        Factory.send(method, @name, @attrs)
      end

      should "raise an ArgumentError when #{method} is called with a nonexistant factory" do
        assert_raise(ArgumentError) { Factory.send(method, :bogus) }
      end

      should "recognize either 'name' or :name for Factory.#{method}" do
        assert_nothing_raised { Factory.send(method, @name.to_s) }
        assert_nothing_raised { Factory.send(method, @name.to_sym) }
      end

    end

    should "call the create method from the top-level Factory() method" do
      @factory.expects(:create).with(@attrs)
      Factory(@name, @attrs)
    end

  end

  Factory.definition_file_paths.each do |file|
    should "automatically load definitions from #{file}.rb" do
      Factory.stubs(:require).raises(LoadError)
      Factory.expects(:require).with(file)
      Factory.find_definitions
    end
  end

  should "only load the first set of factories detected" do
    first, second, third = Factory.definition_file_paths
    Factory.expects(:require).with(first).raises(LoadError)
    Factory.expects(:require).with(second)
    Factory.expects(:require).with(third).never
    Factory.find_definitions
  end

end
