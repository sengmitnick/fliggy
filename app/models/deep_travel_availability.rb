# frozen_string_literal: true

class DeepTravelAvailability < ApplicationRecord
  belongs_to :deep_travel_guide

  validates :available_date, presence: true, uniqueness: { scope: :deep_travel_guide_id }
  validates :is_available, inclusion: { in: [true, false] }

  scope :available, -> { where(is_available: true) }
  scope :unavailable, -> { where(is_available: false) }
  scope :for_date_range, ->(start_date, end_date) { where(available_date: start_date..end_date) }
  scope :future, -> { where('available_date >= ?', Date.today) }

  # Get available dates for a guide within a date range
  def self.available_dates_for_guide(guide_id, start_date, end_date)
    where(deep_travel_guide_id: guide_id, is_available: true)
      .where(available_date: start_date..end_date)
      .pluck(:available_date)
  end
end
