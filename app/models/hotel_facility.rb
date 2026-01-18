class HotelFacility < ApplicationRecord
  include DataVersionable
  belongs_to :hotel
end
