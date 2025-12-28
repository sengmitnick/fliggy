class HotelRoom < ApplicationRecord
  belongs_to :hotel

  validates :room_type, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_guests, numericality: { greater_than: 0 }, allow_nil: true
  validates :available_rooms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
