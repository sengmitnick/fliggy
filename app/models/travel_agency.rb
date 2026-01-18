class TravelAgency < ApplicationRecord
  include DataVersionable
  has_many :tour_group_products, dependent: :destroy

  validates :name, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  scope :verified, -> { where(is_verified: true) }
  scope :by_rating, -> { order(rating: :desc) }
  scope :popular, -> { order(sales_count: :desc) }
end
