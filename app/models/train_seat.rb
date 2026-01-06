class TrainSeat < ApplicationRecord
  belongs_to :train
  
  validates :seat_type, presence: true, inclusion: { in: %w[second_class first_class business_class no_seat] }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :available_count, :total_count, numericality: { greater_than_or_equal_to: 0 }
  
  scope :available, -> { where('available_count > 0') }
  scope :by_type, ->(type) { where(seat_type: type) }
  
  # 座位类型的中文名称
  def seat_type_name
    case seat_type
    when 'second_class' then '二等座'
    when 'first_class' then '一等座'
    when 'business_class' then '商务座'
    when 'no_seat' then '无座'
    else seat_type
    end
  end
  
  # 余票状态
  def availability_status
    if available_count > 50
      '充足'
    elsif available_count > 0
      "#{available_count}张"
    else
      '无票'
    end
  end
end
