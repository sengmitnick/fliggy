# frozen_string_literal: true

namespace :images do
  desc "下载所有种子图片到 public/images/"
  task seed: :environment do
    require_relative '../../app/helpers/image_seed_helper'
    
    puts "开始下载种子图片..."
    puts "=" * 50
    
    categories = [:attractions, :hotels, :tickets, :activities, :tours, :packages, :guides, :products]
    
    categories.each do |category|
      ImageSeedHelper.download_category_images(category)
    end
    
    puts "=" * 50
    puts "✅ 所有种子图片下载完成"
  end

  desc "下载指定分类的种子图片，用法: rake images:seed_category[attractions]"
  task :seed_category, [:category] => :environment do |_t, args|
    require_relative '../../app/helpers/image_seed_helper'
    
    category = args[:category]&.to_sym
    
    if category.nil?
      puts "❌ 请指定分类，例如: rake images:seed_category[attractions]"
      puts "可用分类: attractions, hotels, tickets, activities, tours, packages, guides, products"
      exit 1
    end
    
    unless ImageSeedHelper::UNSPLASH_IMAGE_IDS.key?(category)
      puts "❌ 未知分类: #{category}"
      puts "可用分类: #{ImageSeedHelper::UNSPLASH_IMAGE_IDS.keys.join(', ')}"
      exit 1
    end
    
    ImageSeedHelper.download_category_images(category)
    puts "✅ #{category} 图片下载完成"
  end

  desc "清理所有下载的图片"
  task clean: :environment do
    require_relative '../../app/helpers/image_seed_helper'
    
    puts "正在清理所有图片..."
    ImageSeedHelper.clean_all_images
    puts "✅ 清理完成"
  end

  desc "清理指定分类的图片，用法: rake images:clean_category[attractions]"
  task :clean_category, [:category] => :environment do |_t, args|
    require_relative '../../app/helpers/image_seed_helper'
    
    category = args[:category]
    
    if category.nil?
      puts "❌ 请指定分类，例如: rake images:clean_category[attractions]"
      exit 1
    end
    
    ImageSeedHelper.clean_category_images(category)
    puts "✅ #{category} 图片清理完成"
  end

  desc "检查图片下载状态"
  task status: :environment do
    require_relative '../../app/helpers/image_seed_helper'
    
    puts "图片下载状态:"
    puts "=" * 50
    
    categories = [:attractions, :hotels, :tickets, :activities, :tours, :packages, :guides, :products]
    
    categories.each do |category|
      image_ids = ImageSeedHelper::UNSPLASH_IMAGE_IDS[category]
      total = image_ids.size
      
      downloaded = 0
      image_ids.each_with_index do |_, index|
        filename = "#{category.to_s.singularize}_#{index + 1}.jpg"
        local_path = Rails.root.join('public', 'images', category.to_s, filename)
        downloaded += 1 if File.exist?(local_path)
      end
      
      status = downloaded == total ? "✅" : "⚠️ "
      puts "#{status} #{category}: #{downloaded}/#{total}"
    end
    
    puts "=" * 50
  end
end
