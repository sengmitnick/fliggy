module HotelsHelper
  def date_label(date)
    date = Date.parse(date) if date.is_a?(String)
    today = Time.zone.today
    
    case (date - today).to_i
    when 0
      '今天'
    when 1
      '明天'
    when 2
      '后天'
    else
      # Return weekday name for dates beyond 后天
      weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      weekdays[date.wday]
    end
  end

  def rating_text(rating)
    return '暂无评分' if rating.nil? || rating == 0
    
    case rating.round(1)
    when 0.0..2.0
      '较差'
    when 2.1..3.0
      '一般'
    when 3.1..3.5
      '还行'
    when 3.6..4.0
      '不错'
    when 4.1..4.5
      '很好'
    when 4.6..4.8
      '棒极了'
    else
      '完美'
    end
  end

  def hotel_tags(hotel)
    tags = []
    
    # 根据星级添加标签
    if hotel.star_level.present?
      if hotel.star_level >= 5
        tags << { text: '豪华', color: 'purple' }
      elsif hotel.star_level >= 4
        tags << { text: '高档', color: 'blue' }
      elsif hotel.star_level >= 3
        tags << { text: '舒适', color: 'green' }
      end
    end
    
    # 根据品牌添加标签
    if hotel.brand.present?
      tags << { text: "#{hotel.brand}旗下", color: 'orange' }
    end
    
    # 根据酒店类型添加标签
    if hotel.hotel_type == 'homestay'
      tags << { text: '民宿', color: 'pink' }
    end
    
    tags
  end

  def hotel_ranking_text(hotel)
    return nil if hotel.region.blank?
    "《榜单》入选#{hotel.region}酒店品质榜"
  end

  # 亮点图标背景颜色
  def highlight_icon_bg_color(icon)
    case icon
    when 'star'
      'bg-yellow-100'
    when 'fitness'
      'bg-blue-100'
    when 'family'
      'bg-pink-100'
    else
      'bg-gray-100'
    end
  end

  # 亮点图标SVG
  def highlight_icon_svg(icon)
    case icon
    when 'star'
      '<svg class="w-5 h-5 text-yellow-600" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>'.html_safe
    when 'fitness'
      '<svg class="w-5 h-5 text-blue-600" fill="currentColor" viewBox="0 0 24 24"><path d="M20.57 14.86L22 13.43 20.57 12 17 15.57 8.43 7 12 3.43 10.57 2 9.14 3.43 7.71 2 5.57 4.14 4.14 2.71 2.71 4.14l1.43 1.43L2 7.71l1.43 1.43L2 10.57 3.43 12 7 8.43 15.57 17 12 20.57 13.43 22l1.43-1.43L16.29 22l2.14-2.14 1.43 1.43 1.43-1.43-1.43-1.43L22 16.29z"/></svg>'.html_safe
    when 'family'
      '<svg class="w-5 h-5 text-pink-600" fill="currentColor" viewBox="0 0 24 24"><path d="M16 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63C19.68 7.55 18.92 7 18.06 7h-.12c-.86 0-1.62.55-1.9 1.37L13.5 16H16v6h4zM5.5 6c1.11 0 2-.89 2-2s-.89-2-2-2-2 .89-2 2 .89 2 2 2zm.5 15v-6h2.5L5.96 7.63C5.68 6.55 4.92 6 4.06 6h-.12c-.86 0-1.62.55-1.9 1.37L0 14h2.5v6h4z"/></svg>'.html_safe
    else
      '<svg class="w-5 h-5 text-gray-600" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>'.html_safe
    end
  end

  # 设施图片URL
  def facility_image_url(facility)
    case facility
    when /健身房|健身/
      '/images/hotel_rooms/hotel_room_3.jpg'
    when /游泳池|游泳/
      '/images/hotels/hotel_5.jpg'
    when /洗衣房|洗衣/
      '/images/hotel_rooms/hotel_room_8.jpg'
    else
      '/images/hotels/hotel_1.jpg'
    end
  end

  # 设施颜色类
  def facility_color_class(facility)
    case facility
    when /WiFi|网络|停车|行李|洗衣|酒店前台|无烟|餐厅/
      'bg-green-500'
    else
      'bg-blue-500'
    end
  end

  # 是否免费设施
  def free_facility?(facility)
    ['WiFi', '免费WiFi', '行李寄存', '停车场', '公共区域WIFI', '健身房'].include?(facility)
  end

  # 服务特色渐变色类
  def feature_gradient_class(feature)
    case feature
    when /温泉|水疗|SPA|按摩/i
      'from-blue-400 to-blue-600'
    when /美容|美发|美甲/i
      'from-pink-400 to-pink-600'
    when /健身|瑜伽|运动/i
      'from-green-400 to-green-600'
    when /桑拿|汗蒸/i
      'from-orange-400 to-orange-600'
    when /茶室|棋牌|娱乐/i
      'from-purple-400 to-purple-600'
    when /餐厅|餐饮|早餐/i
      'from-yellow-400 to-yellow-600'
    else
      'from-gray-400 to-gray-600'
    end
  end

  # 服务特色图标SVG
  def feature_icon_svg(feature)
    case feature
    when /温泉|水疗|SPA/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M9 2c-1.05 0-2.05.16-3 .46 4.06 1.27 7 5.06 7 9.54 0 4.48-2.94 8.27-7 9.54.95.3 1.95.46 3 .46 5.52 0 10-4.48 10-10S14.52 2 9 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8c.34 0 .68.02 1.01.07C7.9 6.23 6 9.05 6 12s1.9 5.77 4.01 7.93c-.33.05-.67.07-1.01.07z"/></svg>'
    when /按摩/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>'
    when /美容|美发/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/></svg>'
    when /美甲/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>'
    when /健身|瑜伽/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M20.57 14.86L22 13.43 20.57 12 17 15.57 8.43 7 12 3.43 10.57 2 9.14 3.43 7.71 2 5.57 4.14 4.14 2.71 2.71 4.14l1.43 1.43L2 7.71l1.43 1.43L2 10.57 3.43 12 7 8.43 15.57 17 12 20.57 13.43 22l1.43-1.43L16.29 22l2.14-2.14 1.43 1.43 1.43-1.43-1.43-1.43L22 16.29z"/></svg>'
    when /桑拿|汗蒸/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12.5 2C9.46 2 7 4.46 7 7.5s2.46 5.5 5.5 5.5 5.5-2.46 5.5-5.5S15.54 2 12.5 2zM8 15c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm8 0c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z"/></svg>'
    when /茶室|棋牌/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z"/></svg>'
    when /餐厅|餐饮|早餐/i
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z"/></svg>'
    else
      '<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>'
    end
  end
end
