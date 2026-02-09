class Passenger < ApplicationRecord
  include DataVersionable
  belongs_to :user

  validates :name, :id_type, :id_number, presence: true
  validates :id_number, uniqueness: { scope: :user_id }
  validates :phone, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }, allow_blank: true

  # 身份证验证
  validates :id_number, format: { 
    with: /\A[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]\z/, 
    message: "身份证号码格式不正确" 
  }, if: -> { id_type == '身份证' }

  # 在设置新的"本人"之前，自动取消其他"本人"标记
  before_save :unset_other_self, if: :is_self?

  # 根据身份证号计算年龄
  def age
    return nil unless id_type == '身份证' && id_number.present?
    
    # 从身份证号提取出生日期（第7-14位：YYYYMMDD）
    birth_year = id_number[6..9].to_i
    birth_month = id_number[10..11].to_i
    birth_day = id_number[12..13].to_i
    
    birth_date = Date.new(birth_year, birth_month, birth_day)
    today = Date.current
    
    # 计算周岁
    age = today.year - birth_date.year
    age -= 1 if today.month < birth_date.month || (today.month == birth_date.month && today.day < birth_date.day)
    
    age
  rescue ArgumentError
    nil  # 无效日期返回 nil
  end

  # 判断是否为儿童票（12周岁以下）
  def child_ticket?
    age_value = age
    age_value.present? && age_value < 12
  end

  # 获取票种标签文本
  def ticket_type_label
    child_ticket? ? '儿童票' : '成人票'
  end

  private

  def unset_other_self
    user.passengers.where(is_self: true).where.not(id: id).update_all(is_self: false)
  end
end
