class Address < ApplicationRecord
  include DataVersionable
  belongs_to :user

  validates :name, presence: true
  validates :phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: '请输入正确的手机号' }
  validates :province, presence: true
  validates :city, presence: true
  validates :detail, presence: true
  validates :address_type, inclusion: { in: %w[delivery pickup] }

  scope :delivery, -> { where(address_type: 'delivery') }
  scope :pickup, -> { where(address_type: 'pickup') }
  scope :default, -> { where(is_default: true) }

  before_save :set_default_address, if: :is_default?

  def full_address
    "#{province}#{city}#{district}#{detail}"
  end

  private

  def set_default_address
    # 设置为默认地址时，取消其他地址的默认状态
    user.addresses.where.not(id: id).update_all(is_default: false)
  end
end
