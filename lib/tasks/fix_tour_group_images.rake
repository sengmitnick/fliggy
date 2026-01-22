# frozen_string_literal: true

namespace :tour_groups do
  desc "Fix invalid image URLs for tour group products"
  task fix_images: :environment do
    puts "开始修复旅游产品图片URL..."
    
    # 有效的Unsplash图片URL列表
    valid_image_urls = [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1533929736458-ca588d08c8be?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1520760693108-c8bb8944290a?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&h=600&fit=crop'
    ]
    
    count = 0
    updated = 0
    
    TourGroupProduct.find_each do |product|
      count += 1
      
      # 如果image_url为空或包含无效的URL格式，更新它
      if product.image_url.blank? || product.image_url.include?('?w=400&h=600')
        product.update_column(:image_url, valid_image_urls.sample)
        updated += 1
        print "\r已处理 #{count} 个产品, 已更新 #{updated} 个"
      end
    end
    
    puts "\n✅ 完成！共处理 #{count} 个旅游产品, 更新了 #{updated} 个图片URL"
  end
end
