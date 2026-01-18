class FlightPackage < ApplicationRecord

  serialize :features, coder: JSON

  # Validations
  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :original_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :status, inclusion: { in: %w[active inactive] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_price, -> { order(price: :asc) }

  # Instance methods
  def discount_percentage
    return nil unless original_price.present? && original_price > price
    ((original_price - price) / original_price * 100).round
  end
end
