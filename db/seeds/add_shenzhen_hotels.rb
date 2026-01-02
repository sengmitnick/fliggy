# 添加深圳各区酒店数据
puts '正在添加深圳各区酒店数据...'

hotels_data = [
  # 南山区 - 5家
  { name: '深圳万象城洲际酒店', city: '深圳市', address: '深圳市南山区深南大道9668号', price: 2888, star_level: 5, rating: 4.8, is_featured: true },
  { name: '深圳京基100海景大酒店', city: '深圳市', address: '深圳市南山区海德二路1001号', price: 1688, star_level: 5, rating: 4.7, is_featured: true },
  { name: '深圳华侨城酒店', city: '深圳市', address: '深圳市南山区沙河西路8888号', price: 988, star_level: 4, rating: 4.5 },
  { name: '深圳华侯京基万乐酒店', city: '深圳市', address: '深圳市南山区后海大道1016号', price: 1288, star_level: 5, rating: 4.6, is_featured: false },
  { name: '深圳华云堡国际酒店', city: '深圳市', address: '深圳市南山区华云路99号', price: 688, star_level: 4, rating: 4.4 },
  
  # 福田区 - 5家
  { name: '深圳瑞吉酒店', city: '深圳市', address: '深圳市福田区深南大道1003号', price: 1888, star_level: 5, rating: 4.7, is_featured: true },
  { name: '深圳四季酒店', city: '深圳市', address: '深圳市福田区福华三路138号', price: 2188, star_level: 5, rating: 4.8, is_featured: true },
  { name: '深圳JW万豪酒店', city: '深圳市', address: '深圳市福田区深南大道6005号', price: 2588, star_level: 5, rating: 4.9, is_featured: true },
  { name: '深圳南航明华万鸣大酒店', city: '深圳市', address: '深圳市福田区宝安南路1881号', price: 1388, star_level: 5, rating: 4.6 },
  { name: '深圳大中华希尔顿酒店', city: '深圳市', address: '深圳市福田区富华路1003号', price: 1188, star_level: 4, rating: 4.5 },
  
  # 罗湖区 - 2家
  { name: '深圳东门南亚酒店', city: '深圳市', address: '深圳市罗湖区建设路1003号', price: 588, star_level: 4, rating: 4.3 },
  { name: '深圳罗湖嘉里酒店', city: '深圳市', address: '深圳市罗湖区嘉宾路99号', price: 488, star_level: 3, rating: 4.2 },
  
  # 宝安区 - 2家
  { name: '深圳宝安国际机场酒店', city: '深圳市', address: '深圳市宝安区航城大道1号', price: 688, star_level: 4, rating: 4.4, is_featured: false },
  { name: '深圳远洋酒店', city: '深圳市', address: '深圳市宝安区新安二路100号', price: 388, star_level: 3, rating: 4.1 },
  
  # 龙华区 - 2家
  { name: '深圳大梅沙大酒店', city: '深圳市', address: '深圳市龙华区梅观路1号', price: 488, star_level: 3, rating: 4.2 },
  { name: '深圳龙岸万丽酒店', city: '深圳市', address: '深圳市龙华区龙岸路368号', price: 888, star_level: 4, rating: 4.5, is_featured: false }
]

count = 0
hotels_data.each do |data|
  # 检查是否已存在相同名称和地址的酒店
  exists = Hotel.exists?(name: data[:name], address: data[:address])
  if exists
    puts "  ⊗ 跳过: #{data[:name]} (已存在)"
  else
    hotel = Hotel.create!(data)
    count += 1
    puts "  ✓ 添加: #{hotel.name} - #{hotel.address}"
  end
end

puts "\n✓ 成功添加 #{count} 家新酒店"
puts "\n=== 深圳酒店最终统计 ==="
puts "深圳酒店总数: #{Hotel.where('city LIKE ?', '%深圳%').count}"
puts "地址包含南山区的酒店: #{Hotel.where('address ILIKE ?', '%南山区%').count}家"
puts "地址包含福田区的酒店: #{Hotel.where('address ILIKE ?', '%福田区%').count}家"
puts "地址包含罗湖区的酒店: #{Hotel.where('address ILIKE ?', '%罗湖区%').count}家"
