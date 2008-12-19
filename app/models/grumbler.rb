class Grumbler < ActiveRecord::Base
  has_many :grumbles
  validates_presence_of :name
end
