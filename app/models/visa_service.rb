class VisaService < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  # 验证
  validates :title, presence: true
  validates :country, presence: true
  validates :service_type, presence: true, inclusion: { in: %w[全国送签 武汉送签 北京送签] }
  validates :success_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :processing_days, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :sales_count, numericality: { greater_than_or_equal_to: 0 }

  # 作用域
  scope :by_service_type, ->(type) { where(service_type: type) if type.present? }
  scope :urgent_only, -> { where(urgent_processing: true) }
  scope :by_country, ->(country) { where(country: country) if country.present? }
  scope :sorted_by_smart, -> { order(Arel.sql('sales_count * 0.7 + success_rate * 0.3 DESC')) }
  scope :sorted_by_price_asc, -> { order(price: :asc) }
  scope :sorted_by_price_desc, -> { order(price: :desc) }
  scope :sorted_by_sales, -> { order(sales_count: :desc) }
end
