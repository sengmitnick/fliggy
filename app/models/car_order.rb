class CarOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :car
  
  validates :pickup_location, presence: { message: '取车地点为必填项' }
end
