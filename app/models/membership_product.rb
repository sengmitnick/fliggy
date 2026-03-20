class MembershipProduct < ApplicationRecord
  include DataVersionable
  
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  # 图片字段: image_url (使用本地路径或外部 URL)
  has_many :membership_orders, dependent: :restrict_with_error
  
  # Category constants
  CATEGORIES = {
    'popular' => '热门商品',
    'spring_festival' => '年货精选',
    'quality' => '品质露营',
    'outdoor' => '户外运动'
  }.freeze
  
  # Region constants  
  REGIONS = {
    'all' => '全部',
    'domestic' => '境内区间',
    'international' => '境外区间'
  }.freeze
  
  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :price_cash, numericality: { greater_than_or_equal_to: 0 }
  validates :price_mileage, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :sales_count, numericality: { greater_than_or_equal_to: 0 }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  
  # Validate that at least one price is set
  validate :at_least_one_price
  
  scope :available, -> { where('stock IS NULL OR stock > 0') }
  scope :featured, -> { where(featured: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_region, ->(region) { where(region: region) if region.present? && region != 'all' }
  scope :sorted_by, ->(sort_by) {
    case sort_by
    when 'price_asc'
      order(Arel.sql('COALESCE(price_cash, 0) + COALESCE(price_mileage, 0) ASC'))
    when 'price_desc'
      order(Arel.sql('COALESCE(price_cash, 0) + COALESCE(price_mileage, 0) DESC'))
    when 'sales'
      order(sales_count: :desc)
    when 'mileage_asc'
      order(price_mileage: :asc)
    when 'mileage_desc'
      order(price_mileage: :desc)
    else
      # 默认排序：精选商品优先，然后按销量和评分排序
      order(featured: :desc, sales_count: :desc, rating: :desc)
    end
  }
  
  def category_name
    CATEGORIES[category] || category
  end
  
  def region_name
    REGIONS[region] || region
  end
  
  def in_stock?
    stock.nil? || stock > 0
  end
  
  def discount_percentage
    return nil unless original_price && original_price > 0 && price_cash > 0
    ((original_price - price_cash) / original_price * 100).round
  end
  
  def price_display
    parts = []
    parts << "#{price_mileage}里程" if price_mileage > 0
    parts << "#{price_cash}元" if price_cash > 0
    parts.join(' + ')
  end
  
  private
  
  def at_least_one_price
    if price_cash.to_f <= 0 && price_mileage.to_i <= 0
      errors.add(:base, '至少需要设置一个价格(现金或里程)')
    end
  end
end
