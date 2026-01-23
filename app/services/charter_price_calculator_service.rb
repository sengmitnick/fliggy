class CharterPriceCalculatorService < ApplicationService
  attr_reader :route, :vehicle_type, :duration_hours, :departure_date

  def initialize(route:, vehicle_type:, duration_hours:, departure_date:)
    @route = route
    @vehicle_type = vehicle_type
    @duration_hours = duration_hours
    @departure_date = departure_date
  end

  def call
    calculate_price
  end

  private

  def calculate_price
    base_price = vehicle_type.price_for_duration(duration_hours)
    final_price = base_price * holiday_markup * peak_season_markup
    final_price.round(2)
  end

  def holiday_markup
    # Weekend markup: 20%
    return 1.2 if weekend?
    
    # Special holidays markup: 30%
    return 1.3 if special_holiday?
    
    # Regular day
    1.0
  end

  def peak_season_markup
    # Peak season (May Day, National Day, Spring Festival): 10% additional
    return 1.1 if peak_season?
    
    # Regular season
    1.0
  end

  def weekend?
    departure_date.saturday? || departure_date.sunday?
  end

  def special_holiday?
    # Check if date is in major holidays
    # Spring Festival, National Day, etc.
    # This is a simplified version
    month = departure_date.month
    day = departure_date.day
    
    # National Day Golden Week (Oct 1-7)
    return true if month == 10 && day <= 7
    
    # May Day (May 1-5)
    return true if month == 5 && day <= 5
    
    false
  end

  def peak_season?
    # Peak travel months: April-October
    (4..10).cover?(departure_date.month)
  end
end
