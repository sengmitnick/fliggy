class AttractionActivity < ApplicationRecord
  include DataVersionable
  belongs_to :attraction
  has_many :activity_orders, dependent: :destroy
  # 图片字段: image_url (使用本地路径或外部 URL)
  
  validates :name, presence: true
  validates :current_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :activity_type, inclusion: { in: %w[experience ride show dining photo_service 互动体验 交通工具 动物互动 娱乐演出 摄影服务 水上运动 运动体验 餐饮服务] }
  
  scope :by_type, ->(type) { where(activity_type: type) if type.present? }
  scope :popular, -> { order(sales_count: :desc) }
  
  # 折扣百分比
  def discount_percentage
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - current_price) / original_price * 100).round
  end
end
