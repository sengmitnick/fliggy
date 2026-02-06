class Train < ApplicationRecord
  include DataVersionable
  has_many :train_bookings, dependent: :destroy
  has_many :train_seats, dependent: :destroy
  has_many :booking_options, dependent: :destroy
  
  validates :departure_city, :arrival_city, :departure_time, :arrival_time, presence: true
  validates :train_number, :duration, presence: true
  validates :price_second_class, numericality: { greater_than: 0 }
  validates :available_seats, numericality: { greater_than_or_equal_to: 0 }

  scope :by_route, ->(departure, arrival) { where(departure_city: departure, arrival_city: arrival) }
  scope :by_date, ->(date) { where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", date) }
  scope :available, -> { where('available_seats > ?', 0) }
  scope :high_speed, -> { where("train_number LIKE 'G%' OR train_number LIKE 'D%'") }
  scope :ordered_by_time, ->(direction = :asc) { 
    order(Arel.sql("EXTRACT(HOUR FROM departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') * 60 + EXTRACT(MINUTE FROM departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') #{direction == :desc ? 'DESC' : 'ASC'}"))
  }
  scope :ordered_by_price, -> { order(:price_second_class) }
  scope :ordered_by_duration, -> { order(:duration) }

  # Search trains for a route and date with advanced filters
  def self.search(departure_city, arrival_city, date, options = {})
    # Query trains for this route and date (NO auto-generation)
    trains = by_route(departure_city, arrival_city).by_date(date)
    
    # Apply available filter
    trains = trains.available

    # Apply train type filter (legacy support for only_high_speed)
    trains = trains.high_speed if options[:only_high_speed]
    
    # Apply specific train type filters (advanced filter)
    if options[:train_types] && options[:train_types].any?
      train_type_patterns = options[:train_types].map do |type|
        case type
        when '高铁(G)'
          'G%'
        when '动车(D)'
          'D%'
        when '城际(C/S)'
          ['C%', 'S%']
        when '普通(Z/T/K)'
          ['Z%', 'T%', 'K%']
        when '临时(L)/旅游(Y)'
          ['L%', 'Y%']
        end
      end.flatten.compact
      
      if train_type_patterns.any?
        conditions = train_type_patterns.map { "train_number LIKE ?" }.join(' OR ')
        trains = trains.where(conditions, *train_type_patterns)
      end
    end
    
    # Apply time range filters
    if options[:departure_time_start] && options[:departure_time_end]
      dep_start = options[:departure_time_start].to_i
      dep_end = options[:departure_time_end].to_i
      if dep_start > 0 || dep_end < 1440
        trains = trains.where(
          "EXTRACT(HOUR FROM departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') * 60 + EXTRACT(MINUTE FROM departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') BETWEEN ? AND ?",
          dep_start, dep_end
        )
      end
    end
    
    if options[:arrival_time_start] && options[:arrival_time_end]
      arr_start = options[:arrival_time_start].to_i
      arr_end = options[:arrival_time_end].to_i
      if arr_start > 0 || arr_end < 1440
        trains = trains.where(
          "EXTRACT(HOUR FROM arrival_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') * 60 + EXTRACT(MINUTE FROM arrival_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') BETWEEN ? AND ?",
          arr_start, arr_end
        )
      end
    end

    # Apply sorting
    sort_order = options[:sort_order] == 'desc' ? :desc : :asc
    case options[:sort_by]
    when 'price'
      trains = trains.ordered_by_price
    when 'duration'
      trains = trains.ordered_by_duration
    else
      trains = trains.ordered_by_time(sort_order)
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
