class TransferPackage < ApplicationRecord
  has_many :transfers, dependent: :nullify

  validates :name, :vehicle_category, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :seats, :luggage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :wait_time, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  serialize :features, coder: JSON

  scope :active, -> { where(is_active: true) }
  scope :by_category, ->(category) { where(vehicle_category: category) }
  scope :ordered, -> { order(priority: :asc, price: :asc) }

  # 车辆类型分类
  VEHICLE_CATEGORIES = {
    'economy_5' => { name: '经济5座', seats: 4, luggage: 2 },
    'comfort_5' => { name: '舒适5座', seats: 4, luggage: 2 },
    'economy_7' => { name: '经济7座', seats: 6, luggage: 3 },
    'comfort_7' => { name: '舒适7座', seats: 6, luggage: 3 },
    'luxury_5' => { name: '豪华5座', seats: 4, luggage: 2 },
    'luxury_7' => { name: '豪华7座', seats: 6, luggage: 3 }
  }.freeze

  # 获取车辆类型名称
  def category_name
    VEHICLE_CATEGORIES.dig(vehicle_category, :name) || vehicle_category
  end

  # 获取推荐座位数
  def recommended_seats
    seats || VEHICLE_CATEGORIES.dig(vehicle_category, :seats) || 4
  end

  # 获取推荐行李数
  def recommended_luggage
    luggage || VEHICLE_CATEGORIES.dig(vehicle_category, :luggage) || 2
  end

  # 计算折扣金额
  def calculated_discount
    return 0 if original_price.nil? || original_price <= price
    original_price - price
  end

  # 获取优惠标签文本
  def discount_tag
    discount = calculated_discount
    return nil if discount <= 0
    "已优惠¥#{discount.to_i}"
  end

  # 获取特性列表
  def features_list
    return [] if features.blank?
    features.is_a?(Array) ? features : [features]
  end

  # 生成默认套餐数据
  def self.generate_default_packages
    return if TransferPackage.any?

    packages_data = [
      {
        name: '阳光出行',
        vehicle_category: 'economy_5',
        seats: 4,
        luggage: 2,
        wait_time: 60,
        refund_policy: '条件退',
        price: 80,
        original_price: 95,
        features: ['免费等60分钟', '条件退'],
        provider: '阳光出行',
        priority: 1,
        is_active: true
      },
      {
        name: '伙力专车',
        vehicle_category: 'economy_5',
        seats: 4,
        luggage: 2,
        wait_time: 60,
        refund_policy: '条件退',
        price: 81,
        original_price: 96,
        features: ['免费等60分钟', '条件退'],
        provider: '伙力专车',
        priority: 2,
        is_active: true
      },
      {
        name: '风韵出行',
        vehicle_category: 'economy_5',
        seats: 4,
        luggage: 2,
        wait_time: 60,
        refund_policy: '条件退',
        price: 82,
        original_price: 97,
        features: ['免费等60分钟', '条件退'],
        provider: '风韵出行',
        priority: 3,
        is_active: true
      },
      {
        name: '旅程约车',
        vehicle_category: 'economy_5',
        seats: 4,
        luggage: 2,
        wait_time: 60,
        refund_policy: '条件退',
        price: 82,
        original_price: 97,
        features: ['免费等60分钟', '条件退'],
        provider: '旅程约车',
        priority: 4,
        is_active: true
      },
      # 舒适5座
      {
        name: '阳光出行',
        vehicle_category: 'comfort_5',
        seats: 4,
        luggage: 2,
        wait_time: 60,
        refund_policy: '条件退',
        price: 91,
        original_price: 106,
        features: ['免费等60分钟', '条件退'],
        provider: '阳光出行',
        priority: 1,
        is_active: true
      },
      {
        name: '900游',
        vehicle_category: 'comfort_5',
        seats: 4,
        luggage: 2,
        wait_time: 60,
        refund_policy: '随时退·迟到赔',
        price: 92,
        original_price: 122,
        features: ['舒心行', '随时退·迟到赔', '免费等60分钟'],
        provider: '900游',
        priority: 2,
        is_active: true
      }
    ]

    packages_data.each do |data|
      TransferPackage.create!(data)
    end
  end
end
