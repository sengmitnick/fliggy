class TourProduct < ApplicationRecord
  include DataVersionable
  belongs_to :destination

  serialize :tags, coder: JSON

  validates :name, presence: true
  validates :product_type, inclusion: { in: %w[hotel attraction tour package] }
  validates :category, inclusion: { in: %w[local nearby seasonal experience] }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :by_category, ->(category) { where(category: category) }
  scope :by_type, ->(type) { where(product_type: type) }
  scope :featured, -> { where(is_featured: true) }
  scope :by_rank, -> { order(rank: :asc) }
  scope :top_rated, -> { order(rating: :desc) }
  scope :popular, -> { order(sales_count: :desc) }
end
