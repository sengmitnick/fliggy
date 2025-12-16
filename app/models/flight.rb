class Flight < ApplicationRecord
  has_many :flight_offers, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :departure_city, :destination_city, :departure_time, :arrival_time, presence: true
  validates :airline, :flight_number, :price, :flight_date, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :available_seats, numericality: { greater_than_or_equal_to: 0 }

  scope :by_route, ->(departure, destination) { where(departure_city: departure, destination_city: destination) }
  scope :by_date, ->(date) { where(flight_date: date) }
  scope :available, -> { where('available_seats > ?', 0) }
  scope :ordered_by_time, -> { order(:departure_time) }

  # Generate flights for a specific route and date
  def self.generate_for_route(departure_city, destination_city, date)
    # Check if flights already exist for this route and date
    existing = by_route(departure_city, destination_city).by_date(date)
    return existing if existing.any?

    # Generate new flights
    airlines = [
      { name: '东航', prefix: 'MU', aircraft: '空客321(中)' },
      { name: '海航', prefix: 'HU', aircraft: '空客330(大)' },
      { name: '川航', prefix: '3U', aircraft: '空客320(中)' },
      { name: '南航', prefix: 'CZ', aircraft: '空客320(中)' },
      { name: '国航', prefix: 'CA', aircraft: '波音737(中)' }
    ]

    airports = {
      '北京' => ['大兴', '首都T2', '首都T3'],
      '杭州' => ['萧山T3', '萧山T4'],
      '上海' => ['虹桥T2', '浦东T2'],
      '深圳' => ['宝安T3'],
      '广州' => ['白云T2']
    }

    departure_airports = airports[departure_city] || ['机场']
    arrival_airports = airports[destination_city] || ['机场']

    flights = []
    base_price = 200 + rand(100)
    
    # Generate 8-10 flights for the day
    (8..10).to_a.sample.times do |i|
      airline_info = airlines.sample
      hour = 7 + (i * 1.5).to_i
      minute = [0, 15, 30].sample
      
      departure_time = date.to_datetime.change(hour: hour, min: minute)
      flight_duration = 2 + rand(0.5..1.5) # 2-3.5 hours
      arrival_time = departure_time + flight_duration.hours

      price = base_price + rand(-50..200)
      discount = [0, 20, 30, 50, 80, 90, 130].sample
      
      flight = create!(
        departure_city: departure_city,
        destination_city: destination_city,
        departure_time: departure_time,
        arrival_time: arrival_time,
        departure_airport: departure_airports.sample,
        arrival_airport: arrival_airports.sample,
        airline: airline_info[:name],
        flight_number: "#{airline_info[:prefix]}#{rand(1000..9999)}",
        aircraft_type: airline_info[:aircraft],
        price: price,
        discount_price: discount,
        seat_class: 'economy',
        available_seats: rand(50..200),
        flight_date: date
      )
      
      # Generate offers for this flight
      flight.generate_offers
      
      flights << flight
    end

    flights
  end

  # Get or generate flights for a route and date
  def self.search(departure_city, destination_city, date)
    flights = by_route(departure_city, destination_city)
              .by_date(date)
              .available
              .ordered_by_time

    if flights.empty?
      flights = generate_for_route(departure_city, destination_city, date)
    end

    flights
  end

  # Generate multiple offers from different providers for this flight
  def generate_offers
    return if flight_offers.any? # Already generated

    providers = [
      { name: '飞猪旅行', type: 'featured' },
      { name: '携程旅行', type: 'cashback' },
      { name: '去哪儿旅行', type: 'standard' },
      { name: '同程旅行', type: 'family' }
    ]

    base_price = price.to_f

    providers.each_with_index do |provider, index|
      # Vary prices slightly between providers
      offer_price = base_price + rand(-30..30)
      original = offer_price + rand(10..50)
      cashback = [0, 0, 20, 34, 90, 95].sample
      
      # Generate discount items
      discount_items = []
      if cashback > 0
        discount_items << "#{rand(1..3)}项至高减¥#{cashback}"
      end
      if rand < 0.3
        discount_items << "返现¥#{rand(10..30)}"
      end

      # Generate services
      services_list = ['经济舱', '仅全额电子发票']
      services_list << '无餐食' if rand < 0.5
      services_list << '到达准点率100%' if rand < 0.3

      # Generate tags
      tags_list = []
      case provider[:type]
      when 'featured'
        tags_list << '超值低价'
        tags_list << '出行无忧'
      when 'cashback'
        tags_list << "认证企业会员加享#{rand(5..10)}元"
        tags_list << "可返#{rand(50..100)}元"
      when 'family'
        tags_list << '专享属服务'
        tags_list << '出行更安心'
      end

      # Additional feature tags
      if rand < 0.4
        tags_list << '旅行套餐'
        tags_list << "含#{rand(300..700)}元旅行券包"
        tags_list << '手提行李7KG/尺寸20'
      end

      if rand < 0.3
        tags_list << '延误无忧'
        tags_list << '+¥49/程'
      end

      # Baggage info
      baggage = ['手提行李7KG/尺寸20', '托运行李20KG', '无免费行李'].sample

      flight_offers.create!(
        provider_name: provider[:name],
        offer_type: provider[:type],
        price: offer_price,
        original_price: original,
        cashback_amount: cashback,
        discount_items: discount_items,
        services: services_list,
        tags: tags_list,
        baggage_info: baggage,
        meal_included: rand < 0.3,
        refund_policy: ['退改¥96起', '退改¥95起', '购买返￥188用车券 延误2小时返'].sample,
        is_featured: provider[:type] == 'featured',
        display_order: index
      )
    end
  end

  # Get offers sorted by price
  def sorted_offers
    flight_offers.ordered
  end

  # Calculate final price after discount
  def final_price
    price - discount_price
  end

  # Format departure time
  def departure_time_formatted
    departure_time.strftime('%H:%M')
  end

  # Format arrival time
  def arrival_time_formatted
    arrival_time.strftime('%H:%M')
  end

  # Calculate flight duration in minutes
  def duration_minutes
    ((arrival_time - departure_time) / 60).to_i
  end

  # Format flight duration
  def duration_formatted
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    "#{hours}小时#{minutes}分钟"
  end

  # Check if this is a direct flight (always true for now)
  def direct_flight?
    true
  end
end
