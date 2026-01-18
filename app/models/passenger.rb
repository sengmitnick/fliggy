class Passenger < ApplicationRecord
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

  private

  def unset_other_self
    user.passengers.where(is_self: true).where.not(id: id).update_all(is_self: false)
  end
end
