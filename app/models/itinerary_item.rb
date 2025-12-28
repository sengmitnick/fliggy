class ItineraryItem < ApplicationRecord
  belongs_to :itinerary
  belongs_to :bookable, polymorphic: true, optional: true
  
  ITEM_TYPES = %w[flight train hotel attraction other].freeze
  
  validates :item_type, inclusion: { in: ITEM_TYPES }
  validates :item_date, presence: true
  
  scope :by_sequence, -> { order(:sequence) }
  scope :by_date, -> { order(:item_date, :sequence) }
end
