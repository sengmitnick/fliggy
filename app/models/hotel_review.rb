class HotelReview < ApplicationRecord
  include DataVersionable
  belongs_to :hotel
  belongs_to :user
end
