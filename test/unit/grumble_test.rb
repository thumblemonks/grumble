require 'test_helper'

class GrumbleTest < ActiveSupport::TestCase

  should_belong_to :target
  should_belong_to :grumbler
  should_require_attributes :subject, :body
  should_have_db_column :anon_grumbler_name


  should "auto-set a UUID" do
    grumble = Factory.build(:grumble)
    assert_nil grumble.uuid
    grumble.save!
    deny grumble.uuid.nil?
  end
    
  context "registered_grumbler?" do
    
    should "be true if a registered grumbler created the grumble" do
      grumble = Factory(:grumble)
      assert grumble.grumbler
      assert grumble.registered_grumbler?
    end
    
    should "be false if an anonymous grumbler created the grumble" do
      grumble = Factory(:grumble, :grumbler => nil)
      assert_nil grumble.grumbler
      deny grumble.registered_grumbler?
    end
    
  end

  context "a grumble" do
    setup { @grumble = Factory(:grumble) }
    should_require_unique_attributes :uuid
    
    context "with a registered grumbler" do
      
      should "delegate grumbler_name to the grumbler if present" do
        @grumble.grumbler.expects(:name)
        @grumble.grumbler_name
      end
      
    end # with a registered grumbler

    
    context "without registered grumbler" do
      setup { @grumble.stubs(:grumbler).returns(nil) }
      
      should_require_attributes :anon_grumbler_name

      should "use the name stored on the grumble as grumbler_name" do
        @grumble.anon_grumbler_name = "Foo Bar"
        assert_equal "Foo Bar", @grumble.grumbler_name
      end      
      
    end # without registered grumbler
    
  end # grumble
end
