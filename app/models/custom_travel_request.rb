class CustomTravelRequest < ApplicationRecord
  # Validations
  validates :destination_city, presence: true
  validates :phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: "请输入有效的手机号" }
  validates :adults_count, numericality: { greater_than_or_equal_to: 0 }
  validates :children_count, numericality: { greater_than_or_equal_to: 0 }
  validates :elders_count, numericality: { greater_than_or_equal_to: 0 }
  validates :days_count, numericality: { greater_than: 0 }
  validates :expected_merchants, inclusion: { in: [1, 2] }

  # Enums
  enum :status, {
    pending: 'pending',      # 待处理
    contacted: 'contacted',  # 已联系
    matched: 'matched',      # 已匹配商家
    completed: 'completed',  # 已完成
    cancelled: 'cancelled'   # 已取消
  }, default: :pending

  # 格式化手机号（隐私保护）
  def formatted_phone
    return '' if phone.blank?
    phone.gsub(/(\d{3})\d{4}(\d{4})/, '\1****\2')
  end

  # 总人数
  def total_people
    adults_count + children_count + elders_count
  end

  # 人数描述
  def people_description
    parts = []
    parts << "#{adults_count}成人" if adults_count > 0
    parts << "#{children_count}儿童" if children_count > 0
    parts << "#{elders_count}老人" if elders_count > 0
    parts.join(' ')
  end
end
