require 'ostruct'

class Api::GeocodingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def reverse_geocode
    lat = params[:lat].to_f
    lng = params[:lng].to_f
    
    if lat.zero? || lng.zero?
      return render json: { error: '无效的经纬度' }, status: :bad_request
    end
    
    # 使用简单的距离计算，找到最近的城市
    # 这里使用了一个简化的方法，实际生产环境应该使用专业的地理编码服务
    city = find_nearest_city(lat, lng)
    
    if city
      render json: { 
        city: city.name,
        pinyin: city.pinyin
      }
    else
      render json: { error: '未找到附近的城市' }, status: :not_found
    end
  end

  private
  
  def find_nearest_city(lat, lng)
    # 主要城市的大致经纬度（用于简单匹配）
    city_coordinates = {
      '北京市' => [39.9042, 116.4074],
      '上海市' => [31.2304, 121.4737],
      '广州市' => [23.1291, 113.2644],
      '深圳市' => [22.5431, 114.0579],
      '成都市' => [30.5728, 104.0668],
      '杭州市' => [30.2741, 120.1551],
      '重庆市' => [29.5630, 106.5516],
      '西安市' => [34.2658, 108.9541],
      '武汉市' => [30.5928, 114.3055],
      '南京市' => [32.0603, 118.7969],
      '天津市' => [39.3434, 117.3616],
      '长沙市' => [28.2282, 112.9388],
      '郑州市' => [34.7466, 113.6254],
      '沈阳市' => [41.8057, 123.4328],
      '哈尔滨市' => [45.8038, 126.5340],
      '昆明市' => [25.0406, 102.7123],
      '青岛市' => [36.0671, 120.3826],
      '大连市' => [38.9140, 121.6147],
      '兰州市' => [36.0671, 103.8343],
      '南昌市' => [28.6820, 115.8579],
      '福州市' => [26.0745, 119.2965],
      '合肥市' => [31.8206, 117.2272],
      '太原市' => [37.8706, 112.5489],
      '石家庄市' => [38.0428, 114.5149],
      '济南市' => [36.6512, 117.1205],
      '南宁市' => [22.8170, 108.3665],
      '乌鲁木齐市' => [43.8256, 87.6168],
      '贵阳市' => [26.6470, 106.6302],
      '三亚市' => [18.2528, 109.5117],
      '海口市' => [20.0444, 110.1999]
    }
    
    min_distance = Float::INFINITY
    nearest_city_name = nil
    
    city_coordinates.each do |city_name, coords|
      distance = calculate_distance(lat, lng, coords[0], coords[1])
      if distance < min_distance
        min_distance = distance
        nearest_city_name = city_name
      end
    end
    
    # 如果距离过远（超过200公里），返回最近的城市但标记为不确定
    if min_distance > 200
      return nil
    end
    
    # 返回城市名称和拼音的结构，不依赖City模型
    OpenStruct.new(
      name: nearest_city_name,
      pinyin: PinYin.of_string(nearest_city_name).join.downcase
    )
  end
  
  # 计算两点间的距离（公里）
  def calculate_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    rkm = 6371 # 地球半径（公里）
    
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg
    
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg
    
    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    
    rkm * c
  end
end
