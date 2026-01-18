class TourGroupBooking < ApplicationRecord
  include DataVersionable
  belongs_to :tour_group_product
  belongs_to :tour_package
  belongs_to :user
  has_many :booking_travelers, dependent: :destroy

  validates :travel_date, presence: true
  validates :adult_count, numericality: { greater_than: 0 }
  validates :child_count, numericality: { greater_than_or_equal_to: 0 }
  validates :contact_name, presence: true
  validates :contact_phone, presence: true
  validates :insurance_type, inclusion: { in: %w[none standard premium] }
  validates :status, inclusion: { in: %w[pending confirmed cancelled completed] }
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  accepts_nested_attributes_for :booking_travelers, allow_destroy: true

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }

  # 计算保险费用
  def insurance_price
    return 0 if insurance_type == 'none'
    
    per_person = case insurance_type
                 when 'standard' then 15
                 when 'premium' then 35
                 else 0
                 end
    
    (adult_count + child_count) * per_person
  end

  # 计算基础价格（不含保险）
  def base_price
    (tour_package.price * adult_count) + (tour_package.child_price * child_count)
  end

  # 计算总价（包含保险）
  def calculate_total_price
    base_price + insurance_price
  end

  # 格式化价格
  def format_total_price
    "¥#{total_price.to_i}"
  end
end
