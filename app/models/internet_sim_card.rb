class InternetSimCard < ApplicationRecord
  include DataVersionable
  serialize :features, coder: JSON

  has_many :internet_orders, as: :orderable, dependent: :destroy

  validates :name, presence: true
  validates :region, presence: true
  validates :validity_days, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sales_count, numericality: { greater_than_or_equal_to: 0 }

  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :popular, -> { order(sales_count: :desc) }
end
