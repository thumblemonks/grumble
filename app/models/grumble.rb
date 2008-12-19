require 'uuidtools'

class Grumble < ActiveRecord::Base
  belongs_to :target
  belongs_to :grumbler
  validates_presence_of :subject, :body, :uuid
  validates_presence_of :anon_grumbler_name, :if => lambda {|g| g.grumbler.blank?}
  validates_uniqueness_of :uuid
  before_validation :set_uuid
  
  def grumbler_name
    grumbler ? grumbler.name : anon_grumbler_name
  end
  
  def registered_grumbler?
    !grumbler.nil?
  end

private 

  def set_uuid  
    self.uuid ||= UUID.random_create.to_s
  end
  
end
