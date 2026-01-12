class VisaOrderTraveler < ApplicationRecord
  belongs_to :visa_order

  validates :name, presence: true
  validates :id_number, presence: true
  validates :phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }
end
