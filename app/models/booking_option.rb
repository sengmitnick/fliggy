class BookingOption < ApplicationRecord
  belongs_to :train

  serialize :benefits, coder: JSON
  
  validates :title, presence: true
  validates :extra_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :priority, numericality: { only_integer: true }
  
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:priority) }
  
  # 获取权益列表
  def benefits_list
    benefits.is_a?(Array) ? benefits : []
  end
end
