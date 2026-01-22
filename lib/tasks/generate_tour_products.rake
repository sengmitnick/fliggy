# frozen_string_literal: true

namespace :tour_products do
  desc "Generate tour products for all destinations"
  task generate: :environment do
    puts "开始为所有目的地生成旅游商品..."
    
    # Unsplash图片ID列表
    unsplash_photo_ids = [
      'Q1p7bh3SHj8', 'tZnbakTUcTI', '6M9xiVgkoN0', 'HOrhCnQsxnQ',
      'mpN7xjKQ_Ns', 'TrhLCn1abMU', 'TVllFyGaLEA', '4Mw7nkQDByk',
      'RCAhiGJsUUE', 'qmf9IWcOcDE', 'wtndoIe5jX8', '4amyOVm9oHc',
      'VviFtDJakYk', 'F2KRf_QfCqw', 'i5Kx0P8A0d4', 'dQ5G0h7sLno',
      '6-L5vBLWKT8', 'g5ZIgGdCx88', 'uN_qFM-eT_Q', '8bghKxNU1j0',
      'QwoNAhbmLLo', '7nrsVjvALnA', '4Yv84VgQkRM', 'pHANr-CpbYM',
      'L19BC2nxBmE', 'jDwHHjoRPqw', 'E4BcLxfXO8k', 'qf0nLMOYNfQ'
    ]
    
    count = 0
    Destination.find_each do |destination|
      # 为每个目的地生成:
      # 必去景点榜 (3个)
      3.times do |i|
        TourProduct.create!(
          destination: destination,
          name: "#{destination.name}必去景点 TOP#{i+1}",
          product_type: 'attraction',
          category: 'local',
          price: rand(50..300),
          original_price: rand(300..500),
          sales_count: rand(100..5000),
          rating: (4.5 + rand * 0.5).round(1),
          tags: ['景点', '必去', '热门'].sample(2),
          description: "#{destination.name}最受欢迎的景点之一",
          image_url: "https://images.unsplash.com/photo-#{unsplash_photo_ids.sample}?w=800&h=600&fit=crop",
          rank: i + 1,
          is_featured: i == 0
        )
        count += 1
      end
      
      # 必住酒店榜 (3个)
      3.times do |i|
        TourProduct.create!(
          destination: destination,
          name: "#{destination.name}精选酒店 TOP#{i+1}",
          product_type: 'hotel',
          category: 'local',
          price: rand(200..800),
          original_price: rand(800..1500),
          sales_count: rand(50..2000),
          rating: (4.0 + rand * 1.0).round(1),
          tags: ['酒店', '豪华', '舒适'].sample(2),
          description: "#{destination.name}高品质住宿体验",
          image_url: "https://images.unsplash.com/photo-#{unsplash_photo_ids.sample}?w=800&h=600&fit=crop",
          rank: i + 1,
          is_featured: i == 0
        )
        count += 1
      end
      
      # 当地体验 (2个)
      2.times do |i|
        TourProduct.create!(
          destination: destination,
          name: "#{destination.name}特色体验",
          product_type: 'tour',
          category: 'experience',
          price: rand(100..500),
          original_price: rand(500..1000),
          sales_count: rand(200..3000),
          rating: (4.5 + rand * 0.5).round(1),
          tags: ['体验', '特色', '当地'].sample(2),
          description: "#{destination.name}深度文化体验",
          image_url: "https://images.unsplash.com/photo-#{unsplash_photo_ids.sample}?w=800&h=600&fit=crop",
          rank: i + 1
        )
        count += 1
      end
      
      # 一日游推荐 (3个)
      3.times do |i|
        TourProduct.create!(
          destination: destination,
          name: "#{destination.name}一日游",
          product_type: 'tour',
          category: 'local',
          price: rand(150..600),
          original_price: rand(600..1200),
          sales_count: rand(300..4000),
          rating: (4.3 + rand * 0.7).round(1),
          tags: ['一日游', '精品', '导游'].sample(2),
          description: "#{destination.name}经典一日游线路",
          image_url: "https://images.unsplash.com/photo-#{unsplash_photo_ids.sample}?w=800&h=600&fit=crop",
          rank: i + 1
        )
        count += 1
      end
      
      # 周边榜 (5个)
      5.times do |i|
        TourProduct.create!(
          destination: destination,
          name: "#{destination.name}周边游",
          product_type: 'tour',
          category: 'nearby',
          price: rand(100..400),
          original_price: rand(400..800),
          sales_count: rand(100..2000),
          rating: (4.0 + rand * 1.0).round(1),
          tags: ['周边', '短途', '休闲'].sample(2),
          description: "#{destination.name}周边精选线路",
          image_url: "https://images.unsplash.com/photo-#{unsplash_photo_ids.sample}?w=800&h=600&fit=crop",
          rank: i + 1
        )
        count += 1
      end
      
      # 时令榜 (5个)
      5.times do |i|
        TourProduct.create!(
          destination: destination,
          name: "#{destination.name}时令特色",
          product_type: 'package',
          category: 'seasonal',
          price: rand(200..800),
          original_price: rand(800..1500),
          sales_count: rand(150..2500),
          rating: (4.2 + rand * 0.8).round(1),
          tags: ['时令', '特价', '套餐'].sample(2),
          description: "#{destination.name}季节限定产品",
          image_url: "https://images.unsplash.com/photo-#{unsplash_photo_ids.sample}?w=800&h=600&fit=crop",
          rank: i + 1
        )
        count += 1
      end
      
      print "\r已处理 #{Destination.where('id <= ?', destination.id).count}/#{Destination.count} 个目的地, 共生成 #{count} 个商品"
    end
    
    puts "\n✅ 完成！共为 #{Destination.count} 个目的地生成了 #{count} 个旅游商品"
  end
end
