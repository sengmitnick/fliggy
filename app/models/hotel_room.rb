class HotelRoom < ApplicationRecord
  belongs_to :hotel

  # 房型分类: overnight(过夜), hourly(钟点房)
  ROOM_CATEGORIES = %w[overnight hourly].freeze

  validates :room_type, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_guests, numericality: { greater_than: 0 }, allow_nil: true
  validates :available_rooms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :room_category, inclusion: { in: ROOM_CATEGORIES }, allow_nil: true

  scope :overnight, -> { where(room_category: 'overnight') }
  scope :hourly, -> { where(room_category: 'hourly') }
end
