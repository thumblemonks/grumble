require 'test_helper'

class TargetsControllerTest < ActionController::TestCase

  context "GET request" do    
    context "with a valid URI that has no grumbles" do
      
      setup do
        json_response { get :show, :target_id => "http://www.example.com/posts/12" }
      end
      
      should "return a 200 status" do
        assert_response :success
      end
    
      should "return JSON data" do
        assert_nothing_raised { JSON.parse(@response.body) }
      end
      
      should "return a 0 grumble count" do
        assert_equal 0, @json_response['target']['grumble_count']
      end
      
      should "return a URI for a new grumble" do
        assert_match %r[/grumbles/new$], @json_response['target']['new_grumble_url']
      end

      should "return a URI for the grumble list" do
        assert_match %r[/grumbles$], @json_response['target']['grumble_index_url']
      end
    
      should "only return expected keys in JSON response" do
        expected_keys = %w[grumble_count new_grumble_url grumble_index_url]
        assert_equal expected_keys.sort, @json_response['target'].keys.sort
      end

      should "have a content type of application/json" do
        assert_equal "application/json", @response.content_type
      end
           
    end # with a valid URI
    
    context "exception handling" do
      
      should "return a 406 status with a non HTTP or HTTPS url" do
        get :show, :target_id => "git://www.example.com/posts/12"
        assert_response :not_acceptable
      end
      
    end # exception handling
    
    should "return a 200 status with a valid HTTPS url" do
      get :show, :target_id => "https://www.example.com/posts/12"
      assert_response :success
    end
    
    should "return the number of grumbles for a URI with grumbles" do
      target = Factory(:target)
      json_response { get :show, :target_id => target.uri }
      assert(@json_response['target']['grumble_count'] > 0)
    end
    
    should "call a callback function if callback parameter is given" do
      get :show, :target_id => "https://www.example.com/posts/12", :callback => 'grumble_loader_1234'
      assert_match %r[document.getElementById\("grumble_loader_1234"\).targetFetched\(.*\)], @response.body
    end
    
  end # GET request (show)

end
