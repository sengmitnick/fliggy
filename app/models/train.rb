class Train < ApplicationRecord
  has_many :train_bookings, dependent: :destroy
  has_many :train_seats, dependent: :destroy
  has_many :booking_options, dependent: :destroy
  
  validates :departure_city, :arrival_city, :departure_time, :arrival_time, presence: true
  validates :train_number, :duration, presence: true
  validates :price_second_class, numericality: { greater_than: 0 }
  validates :available_seats, numericality: { greater_than_or_equal_to: 0 }

  scope :by_route, ->(departure, arrival) { where(departure_city: departure, arrival_city: arrival) }
  scope :by_date, ->(date) { where("DATE(departure_time) = ?", date) }
  scope :available, -> { where('available_seats > ?', 0) }
  scope :high_speed, -> { where("train_number LIKE 'G%' OR train_number LIKE 'D%'") }
  scope :ordered_by_time, -> { order(:departure_time) }
  scope :ordered_by_price, -> { order(:price_second_class) }
  scope :ordered_by_duration, -> { order(:duration) }

  # Generate trains for any route and date (like Flight model)
  def self.generate_for_route(departure_city, arrival_city, date)
    # Check if trains already exist for this route and date
    existing = by_route(departure_city, arrival_city).by_date(date)
    return existing if existing.any?

    # Train types with different characteristics
    train_types = [
      { prefix: 'G', name: '高铁', speed_factor: 1.0, base_price_factor: 1.2 },
      { prefix: 'D', name: '动车', speed_factor: 0.85, base_price_factor: 1.0 }
    ]

    # Calculate base parameters based on city names (for consistency)
    city_hash = (departure_city + arrival_city).bytes.sum
    base_duration = 120 + (city_hash % 300) # 2-7 hours
    base_price = 100 + (city_hash % 400) # 100-500 yuan

    trains = []
    # Generate 6-10 trains for the day
    (6..10).to_a.sample.times do |i|
      train_type = train_types.sample
      hour = 6 + (i * 2) + rand(0..1)
      minute = [0, 15, 30, 45].sample
      
      departure_time = date.to_datetime.change(hour: [hour, 22].min, min: minute)
      duration = (base_duration * train_type[:speed_factor]).to_i + rand(-30..30)
      arrival_time = departure_time + duration.minutes

      # Calculate prices
      second_class = (base_price * train_type[:base_price_factor] + rand(-50..100)).round(1)
      first_class = (second_class * 1.6).round(1)
      business_class = (second_class * 3.0).round(1)
      
      # Generate train number
      train_number = "#{train_type[:prefix]}#{rand(1..99).to_s.rjust(2, '0')}#{rand(1..99).to_s.rjust(2, '0')}"
      
      train = create!(
        departure_city: departure_city,
        arrival_city: arrival_city,
        train_number: train_number,
        departure_time: departure_time,
        arrival_time: arrival_time,
        duration: duration,
        price_second_class: second_class,
        price_first_class: first_class,
        price_business_class: business_class,
        available_seats: rand(50..200)
      )
      
      # 为每趟车创建座位类型数据
      [
        { seat_type: 'second_class', price: second_class, total: rand(300..500) },
        { seat_type: 'first_class', price: first_class, total: rand(100..200) },
        { seat_type: 'business_class', price: business_class, total: rand(20..50) },
        { seat_type: 'no_seat', price: second_class * 0.5, total: 999 }
      ].each do |seat_data|
        available = (seat_data[:total] * rand(0.3..0.9)).to_i
        train.train_seats.create!(
          seat_type: seat_data[:seat_type],
          price: seat_data[:price],
          total_count: seat_data[:total],
          available_count: available
        )
      end
      
      # 为每趟车创建3种订票套餐
      [
        {
          title: '超值7大权益',
          description: '含送站、预约座位、延误退改、分享红包等',
          extra_fee: 59,
          benefits: ['送站服务', '预约座位', '延误退改', '退票无忧', '分享红包', '出行保障', '优先客服'],
          priority: 1,
          is_active: true
        },
        {
          title: '登录12306购票',
          description: '使用12306账号直接购买，享受官方价格',
          extra_fee: 0,
          benefits: ['官方价格', '无额外费用', '账号直购'],
          priority: 2,
          is_active: true
        },
        {
          title: '免登12306购票',
          description: '无顰12306账号，快速下单',
          extra_fee: 25,
          benefits: ['无顰12306', '快速下单', '支付便捷'],
          priority: 3,
          is_active: true
        }
      ].each do |option_data|
        train.booking_options.create!(option_data)
      end
      
      trains << train
    end

    trains
  end

  # Search trains for a route and date (no auto-generation)
  def self.search(departure_city, arrival_city, date, options = {})
    trains = by_route(departure_city, arrival_city)
             .by_date(date)
             .available

    # Apply filters
    trains = trains.high_speed if options[:only_high_speed]

    # Apply sorting
    case options[:sort_by]
    when 'price'
      trains = trains.ordered_by_price
    when 'duration'
      trains = trains.ordered_by_duration
    else
      trains = trains.ordered_by_time
    end

    trains
  end

  # Format departure time
  def departure_time_formatted
    departure_time.strftime('%H:%M')
  end

  # Format arrival time
  def arrival_time_formatted
    arrival_time.strftime('%H:%M')
  end

  # Format duration as "Xh Xmin"
  def duration_formatted
    hours = duration / 60
    minutes = duration % 60
    "#{hours}时#{minutes}分"
  end

  # Get seat availability status
  def seat_status
    if available_seats > 50
      '有票'
    elsif available_seats > 0
      '余票不足'
    else
      '无票'
    end
  end

  # Check if train is high-speed (G/D series)
  def high_speed?
    train_number.start_with?('G', 'D')
  end
end
