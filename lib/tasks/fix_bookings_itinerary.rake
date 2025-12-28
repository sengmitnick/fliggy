namespace :data do
  desc "为现有订单创建行程关联"
  task fix_bookings_itinerary: :environment do
    puts "开始修复订单行程关联..."
    
    # 获取所有没有关联到ItineraryItem的订单
    bookings_without_itinerary = Booking.includes(:flight).where.not(
      id: ItineraryItem.where(bookable_type: 'Booking').select(:bookable_id)
    )
    
    puts "找到 #{bookings_without_itinerary.count} 个未关联的订单"
    
    bookings_without_itinerary.group_by(&:user_id).each do |user_id, user_bookings|
      user = User.find(user_id)
      puts "\n处理用户 #{user.email} 的 #{user_bookings.count} 个订单..."
      
      # 按航班日期分组，每个日期创建一个行程
      user_bookings.group_by { |b| b.flight.flight_date }.each do |flight_date, date_bookings|
        # 获取目的地城市（使用第一个订单的目的地）
        destination = date_bookings.first.flight.destination_city
        
        # 创建行程
        itinerary = user.itineraries.create!(
          title: "#{destination}之行",
          start_date: flight_date,
          end_date: flight_date,
          destination: destination,
          status: flight_date >= Date.today ? 'upcoming' : 'completed'
        )
        
        puts "  创建行程: #{itinerary.title} (#{flight_date})"
        
        # 为每个订单创建行程项
        date_bookings.each_with_index do |booking, index|
          ItineraryItem.create!(
            itinerary: itinerary,
            bookable: booking,
            item_type: 'flight',
            item_date: flight_date,
            sequence: index + 1
          )
          puts "    关联订单: #{booking.flight.airline} #{booking.flight.flight_number}"
        end
      end
    end
    
    puts "\n✅ 完成！共处理 #{bookings_without_itinerary.count} 个订单"
  end
end
