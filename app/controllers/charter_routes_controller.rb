class CharterRoutesController < ApplicationController
  before_action :authenticate_user!

  def show
    # 路线详情页 - 展示路线详情、静态地图、景点列表
    @route = CharterRoute.friendly.find(params[:id])
    @city = @route.city
    @attractions = @route.attractions.order('route_attractions.position')
    
    # 获取出发日期（默认明天）
    @departure_date = params[:departure_date].present? ? Date.parse(params[:departure_date]) : Date.tomorrow
    
    # 计算实际最低价（6小时，所有车型中的最低价）
    @vehicle_types = VehicleType.all
    @min_price = @vehicle_types.map do |vehicle|
      CharterPriceCalculatorService.call(
        route: @route,
        vehicle_type: vehicle,
        duration_hours: 6,
        departure_date: @departure_date
      )
    end.min
    
    # 静态地图图片（使用Unsplash占位图）
    @map_image_url = "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&h=400&fit=crop"
  end

  def search
    # 路线搜索页面 - 按城市、类别筛选路线
    @city = params[:city].present? ? City.find_by(name: params[:city]) : City.find_by(name: '武汉')
    @category = params[:category] || 'all'
    
    # 获取出发日期（从URL参数或默认明天）
    @departure_date = params[:date].present? ? Date.parse(params[:date]) : Date.tomorrow
    
    # 获取所有城市并按地区分组（用于城市选择器）
    # 使用与首页相同的精选旅游城市列表
    
    # 国内热门旅游城市（按知名度和旅游热度排序）
    domestic_hot_cities = [
      # 直辖市
      '北京', '上海', '重庆', '天津',
      # 一线旅游城市
      '杭州', '成都', '西安', '南京', '武汉', '苏州', '大连',
      '厦门', '深圳', '广州', '珠海', '三亚', '丽江', '桂林',
      '青岛', '济南', '烟台', '长沙', '哈尔滨',
      '长春', '沈阳', '大同', '洛阳', '郑州', '合肥', '南昌',
      '福州', '昆明', '贵阳', '兰州', '乌鲁木齐', '吐鲁番',
      '拉萨', '西宁', '东莞', '佛山', '中山', '惠州', '南宁',
      # 特别行政区
      '香港', '澳门'
    ]
    
    # 国外热门旅游城市（按地区和热度排序）
    international_hot_cities = [
      # 东亚
      '东京', '大阪', '京都', '冲绳', '札幌', '福冈',
      '首尔', '釜山', '济州',
      # 东南亚
      '曼谷', '普吉', '清迈', '芭提雅',
      '新加坡',
      '吉隆坡', '槟城',
      '河内', '胡志明', '芽庄',
      # 欧洲
      '巴黎', '伦敦', '罗马', '巴塞罗那', '阿姆斯特丹',
      '慕尼黑',
      # 北美
      '纽约', '洛杉矶', '旧金山', '拉斯维加斯',
      '温哥华', '多伦多', '蒙特利尔',
      # 大洋洲
      '悉尼', '墨尔本', '黄金海岸', '奥克兰',
      # 中东
      '迪拜',
      # 其他
      '伊斯坦布尔', '开罗'
    ]
    
    # 合并国内外热门城市
    all_hot_city_names = domestic_hot_cities + international_hot_cities
    
    # 只查询热门旅游城市
    all_cities = City.where(name: all_hot_city_names).order(:name)
    grouped_cities = all_cities.group_by(&:region)
    
    # 定义国内省份/直辖市顺序（按热门程度）
    domestic_regions = [
      '北京', '上海', '广东', '浙江', '江苏', '四川', '湖北', '陕西', 
      '重庆', '天津', '福建', '湖南', '云南', '山东', '海南', '辽宁',
      '河北', '河南', '安徽', '江西', '山西', '吉林', '黑龙江', 
      '广西', '贵州', '甘肃', '新疆', '内蒙古', '西藏', '青海', '宁夏',
      '香港', '澳门', '台湾'
    ]
    
    # 定义国际地区顺序（按热门程度）
    international_regions = [
      '日本', '韩国', '泰国', '新加坡', '马来西亚', '越南',
      '美国', '加拿大', '英国', '法国', '意大利', '西班牙', '德国', '荷兰',
      '澳大利亚', '新西兰', '阿联酋', '土耳其', '埃及', '肯尼亚'
    ]
    
    # 按优先级重新组织城市数据
    @cities_by_region = {}
    
    # 1. 先添加国内城市
    domestic_regions.each do |region|
      if grouped_cities[region]
        @cities_by_region[region] = grouped_cities[region]
      end
    end
    
    # 2. 再添加国际城市
    international_regions.each do |region|
      if grouped_cities[region]
        @cities_by_region[region] = grouped_cities[region]
      end
    end
    
    # 获取路线列表
    @routes = CharterRoute.includes(:city, :attractions)
                          .where(city: @city)
    
    # 按类别筛选
    @routes = @routes.where(category: @category) unless @category == 'all'
    
    @routes = @routes.order(created_at: :desc)
    
    # 计算所有路线的实际最低价（6小时，所有车型中的最低价）
    @route_prices = {}
    @vehicle_types = VehicleType.all
    @routes.each do |route|
      min_price = @vehicle_types.map do |vehicle|
        CharterPriceCalculatorService.call(
          route: route,
          vehicle_type: vehicle,
          duration_hours: 6,
          departure_date: @departure_date
        )
      end.min
      @route_prices[route.id] = min_price
    end
    
    # 静态地图图片（显示所有路线的起点）
    @map_image_url = "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&h=400&fit=crop"
  end

  private
  # Write your private methods here
end
