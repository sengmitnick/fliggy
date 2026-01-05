class BookingTraveler < ApplicationRecord
  belongs_to :tour_group_booking

  validates :traveler_name, presence: true
  validates :id_number, presence: true, format: { with: /\A\d{15}|\d{17}[\dXx]\z/, message: "身份证号格式不正确" }
  validates :traveler_type, inclusion: { in: %w[adult child] }

  # 身份证号脱敏显示
  def masked_id_number
    return '' if id_number.blank?
    "#{id_number[0..5]}********#{id_number[-4..-1]}"
  end
end
