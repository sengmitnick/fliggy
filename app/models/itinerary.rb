class Itinerary < ApplicationRecord
  include DataVersionable
  belongs_to :user
  has_many :itinerary_items, dependent: :destroy
  
  STATUSES = %w[upcoming ongoing completed cancelled].freeze
  
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :start_date, presence: true
  
  scope :upcoming, -> { where(status: 'upcoming').where('start_date >= ?', Date.today) }
  scope :ongoing, -> { where(status: 'ongoing') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_date, -> { order(:start_date) }
  
  def flight_items
    itinerary_items.where(item_type: 'flight')
  end
  
  def hotel_items
    itinerary_items.where(item_type: 'hotel')
  end
end
