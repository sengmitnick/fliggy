class TourItineraryDay < ApplicationRecord
  include DataVersionable
  belongs_to :tour_group_product

  serialize :attractions, coder: JSON

  validates :day_number, presence: true, numericality: { greater_than: 0 }
  validates :title, presence: true

  scope :by_day_order, -> { order(day_number: :asc) }

  def duration_hours
    duration_minutes / 60.0 if duration_minutes > 0
  end

  def format_duration
    return nil if duration_minutes == 0
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    return "#{hours}小时" if minutes == 0
    return "#{minutes}分钟" if hours == 0
    "#{hours}小时#{minutes}分钟"
  end
end
