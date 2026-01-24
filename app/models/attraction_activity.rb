class AttractionActivity < ApplicationRecord
  include DataVersionable
  belongs_to :attraction
  has_many :activity_orders, dependent: :destroy
  has_one_attached :image
  
  validates :name, presence: true
  validates :current_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :activity_type, inclusion: { in: %w[experience ride show dining photo_service] }
  
  scope :by_type, ->(type) { where(activity_type: type) if type.present? }
  scope :popular, -> { order(sales_count: :desc) }
  
  # 折扣百分比
  def discount_percentage
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - current_price) / original_price * 100).round
  end
end
