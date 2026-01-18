class PriceAlert < ApplicationRecord
  validates :departure, presence: true
  validates :destination, presence: true
  validates :expected_price, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active inactive] }
  
  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
end
