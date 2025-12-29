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

  # Generate multiple pricing packages for this flight
  def generate_offers
    return if flight_offers.any? # Already generated

    base_price = price.to_f

    # Package 1: 超值精选 (Best Value)
    flight_offers.create!(
      provider_name: '超值精选',
      offer_type: 'featured',
      price: base_price,
      original_price: base_price + 42,
      cashback_amount: 0,
      discount_items: ['无免费托运行李'],
      services: ['退改MU92起', '经济舱', '仅全额电子发票'],
      tags: ['含合餐权益', '手提行李7KG/尺寸20'],
      baggage_info: '手提行李7KG/尺寸20',
      meal_included: false,
      refund_policy: '退改¥92起',
      is_featured: true,
      display_order: 0
    )

    # Package 2: 选座无忧 (Seat Selection)
    flight_offers.create!(
      provider_name: '选座无忧',
      offer_type: 'standard',
      price: base_price + 8,
      original_price: base_price + 50,
      cashback_amount: 24,
      discount_items: ['无免费托运行李'],
      services: ['退改MU92起', '经济舱', '仅全额电子发票'],
      tags: ['含合餐权益', '手提行李7KG/尺寸20'],
      baggage_info: '含合餐权益',
      meal_included: false,
      refund_policy: '手提行李7KG/尺寸20',
      is_featured: false,
      display_order: 1
    )

    # Package 3: 返现礼遇 (Cashback Package)
    flight_offers.create!(
      provider_name: '返现礼遇',
      offer_type: 'cashback',
      price: base_price + 120,
      original_price: base_price + 220,
      cashback_amount: 90,
      discount_items: ['无免费托运行李'],
      services: ['经济舱', '全额电子发票'],
      tags: [
        '返¥520里程礼包',
        '手提行李7KG/尺寸20',
        '成人可订返现',
        '仅限预定电子票'
      ],
      baggage_info: '返¥520里程礼包',
      meal_included: false,
      refund_policy: '手提行李7KG/尺寸20',
      is_featured: false,
      display_order: 2
    )

    # Package 4: 家庭好选 (Family Choice)
    flight_offers.create!(
      provider_name: '家庭好选',
      offer_type: 'family',
      price: base_price + 5,
      original_price: base_price + 40,
      cashback_amount: 20,
      discount_items: ['结果送出票'],
      services: ['经济舱', '1.7折'],
      tags: [
        '结果送出票',
        '结果提交'
      ],
      baggage_info: '结果送出票',
      meal_included: false,
      refund_policy: '结果提交',
      is_featured: false,
      display_order: 3
    )
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

  # 简化的时长显示，用于航班列表
  def duration
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    "#{hours}h#{minutes}m"
  end

  # 中转信息（当前都是直飞）
  def transfer_info
    direct_flight? ? "直飞" : "1次中转"
  end

  # 准点率（模拟数据）
  def punctuality_rate
    (85 + rand(10)).to_i
  end

  # Check if this is a direct flight (always true for now)
  def direct_flight?
    true
  end
end
