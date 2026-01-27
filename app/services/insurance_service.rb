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

  # Get standalone insurance product by embedding code
  def self.get_standalone_product(insurance_type)
    return nil if insurance_type.to_sym == :none
    InsuranceProduct.embeddable.find_by(embedding_code: insurance_type.to_s)
  end

  # Create insurance order from booking (for embedded insurance)
  def self.create_insurance_order_from_booking(booking, user:)
    return nil if booking.insurance_type.blank? || booking.insurance_type == 'none'
    return nil if booking.insurance_price.blank? || booking.insurance_price.zero?

    product = get_standalone_product(booking.insurance_type)
    return nil unless product

    # Determine dates based on booking type
    start_date, end_date = extract_booking_dates(booking)
    return nil unless start_date && end_date

    # Determine destination
    destination = extract_booking_destination(booking)
    destination_type = extract_booking_destination_type(booking)

    # Create insurance order
    InsuranceOrder.create!(
      user: user,
      insurance_product: product,
      source: 'embedded',
      start_date: start_date,
      end_date: end_date,
      destination: destination,
      destination_type: destination_type,
      insured_persons: [{ name: user.name.presence || user.email.split('@').first, id_number: '' }],
      unit_price: booking.insurance_price,
      quantity: 1,
      status: 'paid',
      paid_at: booking.created_at,
      related_booking: booking
    )
  end

  private

  def self.extract_booking_dates(booking)
    case booking
    when Booking  # Flight booking
      departure_date = booking.departure_time&.to_date
      return_date = booking.return_time&.to_date || departure_date
      [departure_date, return_date]
    when HotelBooking
      [booking.check_in_date, booking.check_out_date]
    when TrainBooking
      departure_date = booking.departure_time&.to_date
      [departure_date, departure_date]
    else
      [nil, nil]
    end
  end

  def self.extract_booking_destination(booking)
    case booking
    when Booking  # Flight booking
      booking.arrival_city || booking.destination
    when HotelBooking
      booking.city
    when TrainBooking
      booking.train.arrival_city
    else
      '未知目的地'
    end
  end

  def self.extract_booking_destination_type(booking)
    case booking
    when Booking
      booking.trip_type == 'international' ? 'international' : 'domestic'
    when HotelBooking
      'domestic'  # Hotels are primarily domestic
    when TrainBooking
      'domestic'
    else
      'domestic'
    end
  end
end
