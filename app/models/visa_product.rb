class VisaProduct < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :country
  has_many :visa_orders, dependent: :destroy

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :processing_days, numericality: { greater_than: 0 }, allow_nil: true
  validates :success_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
end
