require 'test_helper'

class GrumblesControllerTest < ActionController::TestCase
    
  should "call a callback function if callback=true parameter is given" do
    get :index, :target_id => "http://www.example.com/posts/12/", :callback => "true"
    assert_match %r[Grumble.getGrumbles\(.*\)], @response.body
  end
  
  context "GET request with valid target" do
    setup do
      @target = Factory(:target)
      json_response { get :index, :target_id => @target.uri }
    end
    
    should "return a JSON list of grumbles" do
      assert_equal @target.grumbles.size, @json_response['grumbles'].size
    end
 
    context "returned grumble" do
      context "by a non registered grumbler" do
        setup do 
          grumble = @target.grumbles.detect { |g| !g.registered_grumbler? }
          @json_grumble = @json_response['grumbles'].detect { |g| g['id'] == grumble.uuid }
        end

        should "have a grumble_url" do
          deny @json_grumble['grumble_url'].blank?          
        end

        should "have a grumbler_name" do
          deny @json_grumble['grumbler_name'].blank?
        end
        
        should "not have a grumbler_url" do
          assert @json_grumble['grumbler_url'].blank?
        end

        should "have a subject" do
          deny @json_grumble['subject'].blank?
        end
        
        should "have a body" do
          deny @json_grumble['body'].blank?
        end
        
        should "have a created_at" do
          deny @json_grumble['created_at'].blank?
        end
       
      end # by a non registered grumbler
      
      context "by a registered grumbler" do
        setup do 
          grumble = @target.grumbles.detect(&:registered_grumbler?)
          @json_grumble = @json_response['grumbles'].detect { |g| g['id'] == grumble.uuid }
        end

        should "have a grumble_url" do
          deny @json_grumble['grumble_url'].blank?          
        end

        should "have a grumbler_name" do
          deny @json_grumble['grumbler_name'].blank?
        end          
        
        should "have a grumbler_url" do
          deny @json_grumble['grumbler_url'].blank?
        end
        
        should "have a subject" do
          deny @json_grumble['subject'].blank?
        end
        
        should "have a body" do
          deny @json_grumble['body'].blank?
        end
        
        should "have a created_at" do
          deny @json_grumble['created_at'].blank?
        end
        
      end # by a registered grumbler
   
    end # returned grumbles
    
  end # GET
  
  context "POST request with valid target" do

    context "with valid grumble attributes and a brand new target" do
      setup do
        @target = Factory.build(:target)
        grumble_attrs = Factory.attributes_for(:grumble)
        json_response { post :create, :target_id => @target.uri, :grumble => grumble_attrs }
        @json_grumble = @json_response['grumble']
      end
     
      should_change "Target.count", :by => 1
      should_change "Grumble.count", :by => 1

      should "create a target with the URI specified" do
        assert Target.find_by_uri(@target.uri)
      end
      
    end # with valid grumble attributes and a brand new target
    
    setup do
      @target = Factory(:target)
    end
    
    context "by a non registered user" do
      
      should "call a callback function if callback=true parameter is given" do
        grumble_attrs = Factory.attributes_for(:grumble)
        post :create, :target_id => @target.uri, :grumble => grumble_attrs, :callback => 'true'
        assert_match %r[Grumble.grumbleCreated\(.*\)], @response.body
      end
      
      context "with valid grumble attributes" do
        setup do
          grumble_attrs = Factory.attributes_for(:grumble)
          json_response { post :create, :target_id => @target.uri, :grumble => grumble_attrs }
          @json_grumble = @json_response['grumble']
        end
        
        should "respond with 201 created" do
          assert_response :created
        end
        
        should "have a grumble_url" do
          deny @json_grumble['grumble_url'].blank?          
        end

        should "have a grumbler_name" do
          deny @json_grumble['grumbler_name'].blank?
        end
        
        should "not have a grumbler_url" do
          assert @json_grumble['grumbler_url'].blank?
        end

        should "have a subject" do
          deny @json_grumble['subject'].blank?
        end
        
        should "have a body" do
          deny @json_grumble['body'].blank?
        end
        
        should "have a created_at" do
          deny @json_grumble['created_at'].blank?
        end
      end # with valid grumble attributes

      context "with invalid grumble attributes" do
        setup do
          grumble_attrs = Factory.attributes_for(:grumble).except(:subject)
          json_response { post :create, :target_id => @target.uri, :grumble => grumble_attrs }
        end
        
        should "return a 406 not acceptable" do
          assert_response :not_acceptable
        end
        
      end
            
    end # by a non registered user
    
  end # POST request with valid target
  
end
