namespace :cache do
  desc "Clear all application caches"
  task clear_all: :environment do
    Rails.cache.clear
    puts "✅ All caches cleared"
  end

  desc "Clear city data cache"
  task clear_cities: :environment do
    Rails.cache.delete('cities/hot_cities')
    Rails.cache.delete('cities/all_cities')
    puts "✅ City caches cleared"
  end

  desc "Warm up city data cache"
  task warmup_cities: :environment do
    puts "Warming up city caches..."
    
    hot_cities = City.hot_cities.order(:pinyin).to_a
    Rails.cache.write('cities/hot_cities', hot_cities, expires_in: 24.hours)
    puts "  ✓ Hot cities cached (#{hot_cities.count} records)"
    
    all_cities = City.all.order(:pinyin).to_a
    Rails.cache.write('cities/all_cities', all_cities, expires_in: 24.hours)
    puts "  ✓ All cities cached (#{all_cities.count} records)"
    
    puts "✅ City caches warmed up successfully"
  end
end
