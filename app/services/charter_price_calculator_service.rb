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
    # 基础价格：使用路线的 price_from（已包含城市、距离、景点等因素）
    base_price = route.price_from
    
    # 车型系数：根据车型档次调整价格
    vehicle_markup = calculate_vehicle_markup
    
    # 时长系数：8小时比6小时贵
    duration_markup = calculate_duration_markup
    
    # 最终价格 = 基础价格 × 车型系数 × 时长系数 × 节假日系数 × 旺季系数
    final_price = base_price * vehicle_markup * duration_markup * holiday_markup * peak_season_markup
    final_price.round(2)
  end

  def calculate_vehicle_markup
    # 根据车型档次调整价格
    # 经济型作为基准(1.0倍)，其他车型按档次递增
    case vehicle_type.level
    when '经济'
      1.0
    when '舒适'
      1.25
    when '豪华'
      1.8
    else
      1.0
    end
  end

  def calculate_duration_markup
    # 时长系数
    case duration_hours
    when 6
      1.0  # 6小时作为基准
    when 8
      1.3  # 8小时比6小时贵30%
    else
      duration_hours / 6.0  # 其他时长按比例计算
    end
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
