namespace :flights do
  desc "为所有城市对生成航班数据(排列组合全覆盖)"
  task generate_full_coverage: :environment do
    puts "开始生成航班数据全覆盖..."
    
    start_date = Date.today
    end_date = start_date + 30.days
    
    hot_cities = City.where(is_hot: true).pluck(:name)
    all_cities = City.pluck(:name)
    
    puts "热门城市数: #{hot_cities.count}"
    puts "总城市数: #{all_cities.count}"
    
    routes_to_generate = []
    
    # 1. 热门城市之间的双向航线 (16×15=240条路线)
    puts "\n1. 生成热门城市之间的航线..."
    hot_cities.each do |departure|
      hot_cities.each do |destination|
        next if departure == destination
        routes_to_generate << [departure, destination]
      end
    end
    
    # 2. 每个非热门城市与热门城市的双向航线
    puts "2. 生成非热门城市与热门城市的航线..."
    non_hot_cities = all_cities - hot_cities
    non_hot_cities.each do |city|
      hot_cities.each do |hot_city|
        routes_to_generate << [city, hot_city]
        routes_to_generate << [hot_city, city]
      end
    end
    
    # 3. 同区域城市之间的航线
    puts "3. 生成同区域城市之间的航线..."
    regions = City.group(:region).count
    regions.keys.each do |region|
      region_cities = City.where(region: region).pluck(:name)
      next if region_cities.count < 2
      
      region_cities.combination(2).each do |city1, city2|
        routes_to_generate << [city1, city2]
        routes_to_generate << [city2, city1]
      end
    end
    
    # 去重
    routes_to_generate.uniq!
    
    puts "\n总共需要生成 #{routes_to_generate.count} 条航线"
    puts "每条航线生成30天的数据，每天8-10个航班"
    puts "预计生成航班总数: #{routes_to_generate.count * 30 * 9} 个左右\n"
    
    # 批量生成
    generated_routes = 0
    generated_flights = 0
    skipped_routes = 0
    
    routes_to_generate.each_with_index do |(departure, destination), index|
      # 检查是否已有数据(检查未来30天内是否有航班)
      existing = Flight.by_route(departure, destination)
                      .where(flight_date: start_date..end_date)
      
      if existing.any?
        skipped_routes += 1
        next
      end
      
      # 为每一天生成航班
      (start_date..end_date).each do |date|
        flights = Flight.generate_for_route(departure, destination, date)
        generated_flights += flights.count
      end
      
      generated_routes += 1
      
      # 每生成100条路线输出一次进度
      if (index + 1) % 100 == 0
        puts "进度: #{index + 1}/#{routes_to_generate.count} (已生成: #{generated_routes}, 跳过: #{skipped_routes})"
      end
    end
    
    puts "\n✅ 完成!"
    puts "实际生成路线数: #{generated_routes}"
    puts "跳过已有路线数: #{skipped_routes}"
    puts "生成航班总数: #{generated_flights}"
    puts "当前数据库航班总数: #{Flight.count}"
  end
  
  desc "清空所有航班数据"
  task clear_all: :environment do
    puts "正在清空所有航班数据..."
    FlightOffer.delete_all
    Flight.delete_all
    puts "✅ 已清空所有航班数据"
  end
  
  desc "统计航班覆盖情况"
  task stats: :environment do
    puts "航班数据统计"
    puts "=" * 50
    puts "总航班数: #{Flight.count}"
    puts "总航班套餐数: #{FlightOffer.count}"
    puts ""
    
    # 统计路线数
    routes = Flight.select(:departure_city, :destination_city).distinct
    puts "覆盖路线数: #{routes.count}"
    puts ""
    
    # 统计每个城市的出发和到达航班数
    puts "城市航班统计 (Top 20):"
    cities = City.limit(20)
    cities.each do |city|
      departure_count = Flight.where(departure_city: city.name).count
      arrival_count = Flight.where(destination_city: city.name).count
      puts "  #{city.name}: 出发#{departure_count}班, 到达#{arrival_count}班"
    end
    
    puts ""
    puts "未覆盖航线的城市对(随机抽样10对):"
    all_cities = City.pluck(:name)
    uncovered_routes = []
    
    all_cities.sample(10).each do |departure|
      all_cities.sample(10).each do |destination|
        next if departure == destination
        exists = Flight.by_route(departure, destination).exists?
        unless exists
          uncovered_routes << "#{departure} → #{destination}"
        end
      end
    end
    
    if uncovered_routes.any?
      uncovered_routes.first(10).each { |r| puts "  #{r}" }
    else
      puts "  (抽样检查: 所有检查的路线都有数据)"
    end
  end
end
