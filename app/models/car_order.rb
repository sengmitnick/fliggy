class CarOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :car
  
  validates :pickup_location, presence: { message: '取车地点为必填项' }

  # Calculate rental duration in days (rounds up to next day)
  # Formula: ceil((return_time - pickup_time) / 24 hours)
  # Example: 9:00 to 20:00 (11 hours) = 1 day
  # Example: 9:00 today to 9:01 tomorrow (24h 1min) = 2 days
  def rental_days
    return nil unless pickup_datetime && return_datetime
    
    diff_hours = (return_datetime - pickup_datetime) / 3600.0  # Convert seconds to hours
    (diff_hours / 24.0).ceil  # Round up to next day
  end
end
