class Contact < ApplicationRecord
  include DataVersionable
  belongs_to :user

  validates :name, presence: true
  validates :phone, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "邮箱格式不正确" }, allow_blank: true
  validate :at_least_one_contact_method

  # 在设置新的默认之前，自动取消其他默认标记
  before_save :unset_other_default, if: :is_default?

  private

  def unset_other_default
    user.contacts.where(is_default: true).where.not(id: id).update_all(is_default: false)
  end

  def at_least_one_contact_method
    if phone.blank? && email.blank?
      errors.add(:base, "联系手机和联系邮箱至少填写一个")
    end
  end
end
