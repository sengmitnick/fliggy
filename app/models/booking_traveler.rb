class BookingTraveler < ApplicationRecord
  include DataVersionable
  belongs_to :tour_group_booking, optional: true
  belongs_to :deep_travel_booking, optional: true

  validates :traveler_name, presence: true, unless: :skip_traveler_validations?
  validates :id_number, presence: true, format: { with: /\A\d{15}|\d{17}[\dXx]\z/, message: "身份证号格式不正确" }, unless: :skip_traveler_validations?
  validates :traveler_type, inclusion: { in: %w[adult child] }

  # 身份证号脱敏显示
  def masked_id_number
    return '' if id_number.blank?
    "#{id_number[0..5]}********#{id_number[-4..-1]}"
  end

  private

  def skip_traveler_validations?
    # 如果父记录设置了fill_travelers_later,则跳过出行人验证
    (tour_group_booking&.fill_travelers_later == true) || (deep_travel_booking&.fill_travelers_later == true)
  end
end
