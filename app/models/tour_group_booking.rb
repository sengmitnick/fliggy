class TourGroupBooking < ApplicationRecord
  include DataVersionable
  belongs_to :tour_group_product
  belongs_to :tour_package
  belongs_to :user
  has_many :booking_travelers, dependent: :destroy

  validates :travel_date, presence: true
  validates :adult_count, numericality: { greater_than: 0 }
  validates :child_count, numericality: { greater_than_or_equal_to: 0 }
  validates :contact_name, presence: true, unless: :fill_travelers_later?
  validates :contact_phone, presence: true, unless: :fill_travelers_later?
  validates :insurance_type, inclusion: { in: %w[none standard premium] }
  validates :status, inclusion: { in: %w[pending confirmed cancelled completed] }
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  accepts_nested_attributes_for :booking_travelers, allow_destroy: true
  
  validate :unique_traveler_info, unless: :fill_travelers_later?

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

  private

  # 验证出行人信息不重复
  def unique_traveler_info
    return if booking_travelers.empty?
    
    # 过滤掉标记为删除的出行人
    active_travelers = booking_travelers.reject(&:marked_for_destruction?)
    return if active_travelers.empty?
    
    # 检查姓名重复
    names = active_travelers.map(&:traveler_name).compact.reject(&:blank?)
    if names.size != names.uniq.size
      duplicate_names = names.group_by { |n| n }.select { |_, v| v.size > 1 }.keys
      errors.add(:base, "出行人姓名不能重复：#{duplicate_names.join('、')}")
    end
    
    # 检查身份证号重复
    id_numbers = active_travelers.map(&:id_number).compact.reject(&:blank?)
    if id_numbers.size != id_numbers.uniq.size
      duplicate_ids = id_numbers.group_by { |n| n }.select { |_, v| v.size > 1 }.keys
      errors.add(:base, "出行人身份证号不能重复：#{duplicate_ids.map { |id| "#{id[0..5]}****#{id[-4..-1]}" }.join('、')}")
    end
  end
end
