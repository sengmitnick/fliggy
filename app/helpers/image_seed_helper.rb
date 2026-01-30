# frozen_string_literal: true

require 'open-uri'
require 'fileutils'

# 图片种子下载辅助工具
# 用于数据包加载时下载 Unsplash 图片到本地
module ImageSeedHelper
  # Unsplash 图片 ID 池（高质量旅游/酒店图片）
  UNSPLASH_IMAGE_IDS = {
    attractions: [
      '1506905925346-21bda4d32df4', '1464822759023-fed622ff2c3b',
      '1519681393784-d120267933ba', '1523712999610-f77fbcfc3843',
      '1476514525504-03b2457c5982', '1469854523690-44d8caf40d3e',
      '1564501049412-61c2a3083791', '1551244072-5d12893278ab'
    ],
    hotels: [
      '1566073771259-6a8506099945', '1542314831-068cd1dbfeeb',
      '1551882547-ff40c63fe5fa', '1571003123894-1f0594d2b5d9',
      '1582719478250-c89cae4dc85b', '1549294413-26f195200c16',
      '1520250497591-112f2f40a3f4', '1584132967334-10e028bd69f7'
    ],
    tickets: [
      '1564501049412-61c2a3083791', '1469854523690-44d8caf40d3e',
      '1476514525504-03b2457c5982', '1506905925346-21bda4d32df4'
    ],
    activities: [
      '1523712999610-f77fbcfc3843', '1519681393784-d120267933ba',
      '1533929736458-ca588d08c8be', '1551244072-5d12893278ab'
    ],
    tours: [
      'L19BC2nxBmE', 'jDwHHjoRPqw', 'E4BcLxfXO8k', 'qf0nLMOYNfQ',
      '1506905925346-21bda4d32df4', '1464822759023-fed622ff2c3b', 
      '1548919973-5cef591cdbc9', '1508804185872-d7badad00f7d'
    ],
    packages: [
      '1566073771259-6a8506099945', '1582719508461-905c673771fd',
      '1551882547-ff40c63fe5fa'
    ],
    guides: [
      '1507003211169-0a1dd7228f2d', '1544005313-94ddf0286df2',
      '1438761681033-6461ffad8d80'
    ],
    products: [
      '1555881400-74d7acaacd8b', '1533929736458-ca588d08c8be',
      '1503454537195-1dcabb73ffb9'
    ],
    cruises: [
      '1568481572796-cac3501604fc', '1599640842225-85d111c60e6b',
      '1605408499391-6368c628ef42', '1583417319070-4a69db38a482',
      '1571896349842-33c89424de2d', '1540541338287-41700207dee6'
    ],
    flights: [
      '1436491865332-7a61a109cc05', '1464037866556-6812c9d1c72e',
      '1469854523086-cc02fe5d8800', '1476514525535-07fb3b4ae5f1'
    ],
    insurances: [
      '1436491865332-7a61a109cc05', '1464037866556-6812c9d1c72e',
      '1469854523086-cc02fe5d8800', '1476514525535-07fb3b4ae5f1',
      '1488646953014-85cb44e25828', '1506929562872-bb421503ef21'
    ],
    visas: [
      '1467269204594-9661b134dd2b', '1493976040374-85c8e12f0c0e',
      '1502602898657-3e91760cbb34', '1513635269975-59663e0ac1ad',
      '1517154421773-0529f29ea451', '1523906834658-6e24ef2386f9',
      '1525625293386-3f8f99389edd', '1551244072-5d12893278ab',
      '1552465011-b4e21bf6e79a', '1555409290-7896f99c76b2',
      '1583417319070-4a69db38a482', '1596422846543-75c6fc197f07'
    ],
    cars: [
      '1449965023817-8219c0a8cdaf', '1552519507-da3f49e1f26e',
      '1503376780353-7e6692767b70', '1494905998402-395d579af36f',
      '1542362567-b07e54358753', '1583267746965-ac1f34a4654f'
    ],
    shops: [
      '1555881400-74d7acaacd8b', '1488085061387-422e29b40080',
      '1540959733332-eab4deabeeaf', '1533929736458-ca588d08c8be'
    ]
  }.freeze

  # 确保图片目录存在
  def self.ensure_image_directories
    categories = %w[attractions hotels tickets activities tours packages guides products cruises flights insurances visas cars shops]
    categories.each do |category|
      dir = Rails.root.join('public', 'images', category)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end
  end

  # 下载单张图片到本地
  # @param category [String] 图片分类 (attractions, hotels, etc.)
  # @param index [Integer] 图片编号 (1, 2, 3, ...)
  # @param unsplash_id [String] Unsplash 图片 ID
  # @return [String] 本地图片路径 (/images/category/category_N.jpg)
  def self.download_image(category, index, unsplash_id)
    ensure_image_directories
    
    filename = "#{category.to_s.singularize}_#{index}.jpg"
    local_path = Rails.root.join('public', 'images', category.to_s, filename)
    
    # 如果文件已存在，直接返回路径
    if File.exist?(local_path)
      return "/images/#{category}/#{filename}"
    end
    
    # 下载图片
    begin
      image_url = "https://images.unsplash.com/photo-#{unsplash_id}?w=1200&q=80"
      io = URI.open(image_url)
      File.open(local_path, 'wb') do |file|
        file.write(io.read)
      end
      puts "  ✓ 下载图片: #{filename}"
      "/images/#{category}/#{filename}"
    rescue StandardError => e
      puts "  ✗ 下载失败: #{filename} - #{e.message}"
      nil
    end
  end

  # 批量下载某分类的所有图片
  # @param category [Symbol] 图片分类
  # @return [Array<String>] 本地图片路径数组
  def self.download_category_images(category)
    image_ids = UNSPLASH_IMAGE_IDS[category.to_sym]
    return [] if image_ids.blank?
    
    puts "正在下载 #{category} 图片 (#{image_ids.size}张)..."
    
    image_ids.each_with_index.map do |unsplash_id, index|
      download_image(category, index + 1, unsplash_id)
    end.compact
  end

  # 从图片池随机选择一张图片路径
  # @param category [String] 图片分类
  # @return [String] 图片路径
  def self.random_image_from_category(category)
    # 直接从本地已存在的图片中随机选择
    dir = Rails.root.join('public', 'images', category.to_s)
    return nil unless Dir.exist?(dir)
    
    # 获取所有 jpg 图片
    images = Dir.glob("#{dir}/*.jpg").map { |f| File.basename(f) }
    return nil if images.empty?
    
    # 随机选择一张
    filename = images.sample
    "/images/#{category}/#{filename}"
  end

  # 批量随机选择多张图片
  # @param category [String] 图片分类
  # @param count [Integer] 需要的图片数量
  # @return [Array<String>] 图片路径数组
  def self.random_images_from_category(category, count: 3)
    # 直接从本地已存在的图片中随机选择
    dir = Rails.root.join('public', 'images', category.to_s)
    return [] unless Dir.exist?(dir)
    
    # 获取所有 jpg 图片
    images = Dir.glob("#{dir}/*.jpg").map { |f| File.basename(f) }
    return [] if images.empty?
    
    # 随机选择多张（不重复）
    available_count = [count, images.size].min
    selected = images.sample(available_count)
    
    selected.map { |filename| "/images/#{category}/#{filename}" }
  end

  # 清理某分类的所有图片
  # @param category [String] 图片分类
  def self.clean_category_images(category)
    dir = Rails.root.join('public', 'images', category.to_s)
    if Dir.exist?(dir)
      FileUtils.rm_rf(dir)
      puts "  ✓ 已清理 #{category} 图片"
    end
  end

  # 清理所有下载的图片
  def self.clean_all_images
    images_dir = Rails.root.join('public', 'images')
    if Dir.exist?(images_dir)
      FileUtils.rm_rf(Dir.glob("#{images_dir}/*"))
      puts "  ✓ 已清理所有图片"
    end
  end

  # 检查某分类的图片是否已下载
  # @param category [String] 图片分类
  # @return [Boolean]
  def self.category_images_exist?(category)
    image_ids = UNSPLASH_IMAGE_IDS[category.to_sym]
    return false if image_ids.blank?
    
    image_ids.each_with_index.all? do |_, index|
      filename = "#{category.to_s.singularize}_#{index + 1}.jpg"
      local_path = Rails.root.join('public', 'images', category.to_s, filename)
      File.exist?(local_path)
    end
  end

  # 获取某分类的所有本地图片路径
  # @param category [String] 图片分类
  # @return [Array<String>] 图片路径数组
  def self.all_images_for_category(category)
    image_ids = UNSPLASH_IMAGE_IDS[category.to_sym]
    return [] if image_ids.blank?
    
    image_ids.each_with_index.map do |_, index|
      filename = "#{category.to_s.singularize}_#{index + 1}.jpg"
      "/images/#{category}/#{filename}"
    end
  end
end
