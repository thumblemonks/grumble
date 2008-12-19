require 'test_helper'

class GrumblerTest < ActiveSupport::TestCase
  
  should_have_many :grumbles
  should_require_attributes :name
  
end
