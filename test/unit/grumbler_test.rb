require 'test_helper'

class GrumblerTest < ActiveSupport::TestCase
  
  should_have_many :grumbles
  should_validate_presence_of :name
  
end
