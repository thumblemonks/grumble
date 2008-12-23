require 'test_helper'

class TargetTest < ActiveSupport::TestCase

  should_have_many :grumbles

  context "with an existing target" do
    setup { @target = Factory(:target) }
    should_require_unique_attributes :uri  
    
    should "return URI as to_param" do
      assert_equal @target.uri, @target.to_param
    end
    
    should "search on normalized versions of the URI" do
      bad_uri = @target.uri.gsub(%r{/([^/]+)$}, '////\1')
      target = Target.for_uri(bad_uri)
      assert_equal @target, target
    end
  end
  
  context "validate uri-ness of uri" do
    setup do
      @target = Target.new
    end
    
    should "require a uri" do
      assert_bad_value(@target, :uri, nil, /does not have a valid/)
    end
    
    should "normalize the url path" do
      @target.uri = "http://www.example.com////hi/////guys"
      assert_equal("http://www.example.com/hi/guys", @target.uri)
    end
    
    should "preserve the fragment if given" do
      @target.uri = "http://www.example.com/index.html#foo"
      assert_equal("http://www.example.com/index.html#foo", @target.uri)
    end
    
    should "allow http as a URI scheme" do
      assert_good_value(@target, :uri, "http://www.example.com")
    end
    
    should "allow https as a URI scheme" do
      assert_good_value(@target, :uri, "https://www.example.com")      
    end
    
    should "not be valid with no scheme" do
      assert_bad_value(@target, :uri, "www.example.com", /scheme/)
    end
    
    should "only allow http or https schemes" do
      assert_bad_value(@target, :uri, "ldap://www.example.com", /scheme/)
    end
    
    should "not be valid if URI parsing raises an error" do
      assert_bad_value(@target, :uri, "^", /is invalid/)
    end
  end

end
