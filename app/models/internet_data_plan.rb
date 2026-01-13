class InternetDataPlan < ApplicationRecord
  has_many :internet_orders, as: :orderable, dependent: :destroy

  validates :name, presence: true
  validates :region, presence: true
  validates :validity_days, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :carrier, presence: true

  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_carrier, ->(carrier) { where(carrier: carrier) if carrier.present? }
end
