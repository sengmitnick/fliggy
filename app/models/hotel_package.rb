class HotelPackage < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  
  has_one_attached :brand_logo
  has_many :hotel_package_orders, dependent: :destroy
  has_many :package_options, dependent: :destroy
  belongs_to :hotel, optional: true
  
  # 套餐类型: standard(标准), vip(会员), limited(限时)
  PACKAGE_TYPES = %w[standard vip limited].freeze
  
  validates :brand_name, presence: true
  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :original_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :valid_days, numericality: { greater_than: 0 }
  validates :package_type, inclusion: { in: PACKAGE_TYPES }
  
  scope :featured, -> { where(is_featured: true) }
  scope :by_brand, ->(brand) { where(brand_name: brand) if brand.present? }
  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_type, ->(type) { where(package_type: type) if type.present? && PACKAGE_TYPES.include?(type) }
  scope :refundable, -> { where(refundable: true) }
  scope :instant_booking, -> { where(instant_booking: true) }
  scope :luxury, -> { where(luxury: true) }
  scope :ordered, -> { order(display_order: :asc, sales_count: :desc, created_at: :desc) }
  scope :ordered_by_sales, -> { order(sales_count: :desc, created_at: :desc) }
  
  # 计算折扣
  def discount_rate
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - price) / original_price * 100).round(1)
  end
  
  # 是否有折扣
  def has_discount?
    original_price.present? && original_price > price
  end
end
