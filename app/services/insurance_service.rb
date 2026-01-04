# Insurance service for all booking types
class InsuranceService < ApplicationService
  # Insurance types and configurations
  INSURANCE_OPTIONS = {
    none: {
      name: '无保障',
      price: 0,
      coverage: 0,
      medical: 0,
      description: '放弃保障'
    },
    standard: {
      name: '优享保障',
      price: 50,
      coverage: 7_000_000,
      medical: 50_000,
      description: '达人之选'
    },
    premium: {
      name: '至尊保障',
      price: 66,
      coverage: 10_000_000,
      medical: 100_000,
      description: '尊享之选'
    },
    travel_disruption: {
      name: '行程阻碍险',
      price: 25,
      coverage: 0,
      medical: 0,
      hospitalization: 300,
      transportation: 600,
      description: '极端天气、传染病、突发急性病等致旅程不能继续'
    },
    accident_medical: {
      name: '无忧保(意外+传染病)',
      price: 18,
      coverage: 0,
      medical: 0,
      max_coverage: 500_000,
      acute_disease: 50_000,
      hospitalization: 300,
      transportation: 600,
      description: '急性病/传染病医疗费用 意外住院津贴'
    },
    hotel_cancellation: {
      name: '酒店无理由取消险',
      price: 16,
      coverage: 0,
      medical: 0,
      cancellation_refund: 1.0,
      description: '未入住可退赔房损失的100%'
    }
  }.freeze

  # Get insurance option by type
  def self.get_option(type)
    INSURANCE_OPTIONS[type.to_sym] || INSURANCE_OPTIONS[:none]
  end

  # Calculate insurance price based on booking type
  def self.calculate_price(insurance_type, booking_type: :single, trip_count: 1)
    option = get_option(insurance_type)
    base_price = option[:price]

    case booking_type
    when :round_trip
      base_price * 2  # Round trip = double insurance
    when :multi_city
      base_price * trip_count  # Multi-city = price per trip
    else
      base_price  # Single trip
    end
  end

  # Get appropriate insurance options for booking type
  def self.available_options(booking_class:)
    keys = case booking_class
    when 'Flight', 'Booking'
      [:none, :standard, :premium]
    when 'HotelBooking'
      [:none, :travel_disruption, :accident_medical, :hotel_cancellation]
    else
      [:none]
    end
    
    INSURANCE_OPTIONS.slice(*keys)
  end

  # Get insurance details for display
  def self.format_insurance_details(insurance_type, insurance_price)
    option = get_option(insurance_type)
    
    {
      type: insurance_type,
      name: option[:name],
      price: insurance_price,
      description: option[:description],
      coverage: option[:coverage],
      medical: option[:medical]
    }
  end
end
