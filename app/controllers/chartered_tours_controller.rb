class CharteredToursController < ApplicationController
  before_action :authenticate_user!

  def index
    # 定制旅游首页 - 展示个人定制和公司团建两个tab
    # 目前默认显示个人定制tab
    @active_tab = params[:tab] || 'personal'
  end

  def search
    # 包车游城市搜索页面 - 展示城市选择、日期选择、精挑路线
    @selected_city = params[:city].present? ? City.find_by(name: params[:city]) : City.find_by(name: '武汉')
    @departure_date = params[:date].present? ? Date.parse(params[:date]) : (Date.current + 1.day)
    @active_tab = params[:tab] || 'recommend' # recommend, classic, hot
    
    # 获取该城市的包车路线
    if @selected_city
      @routes = CharterRoute.where(city: @selected_city)
      @routes = case @active_tab
                when 'classic'
                  @routes.classic
                when 'hot'
                  @routes.hot
                else
                  @routes.featured
                end
      @routes = @routes.includes(:city, :attractions).order(:name)
    else
      @routes = CharterRoute.none
    end
    
    # 获取热门城市列表（用于城市选择器）
    @hot_cities = City.where(name: ['武汉', '上海', '北京', '广州', '深圳', '杭州', '成都', '西安'])
    
    # 获取所有城市并按地区分组（用于城市选择器）
    # 基于现实旅游热度筛选城市，不依赖数据库是否有数据
    # 优先显示国内城市，国际城市放在后面
    
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
  end

  def vehicles
    # 车型选择页面 - 显示不同时长和车型的价格
    @route = CharterRoute.friendly.find(params[:route_id])
    @departure_date = params[:departure_date].present? ? Date.parse(params[:departure_date]) : Date.tomorrow
    @duration_hours = params[:duration_hours]&.to_i || 6
    @passenger_count = params[:passenger_count]&.to_i || 1
    
    # 获取所有车型
    @vehicle_types = VehicleType.order(:category, :level)
    
    # 为每个车型计算价格（使用CharterPriceCalculatorService）
    @vehicle_prices = @vehicle_types.each_with_object({}) do |vehicle, hash|
      price = CharterPriceCalculatorService.call(
        route: @route,
        vehicle_type: vehicle,
        duration_hours: @duration_hours,
        departure_date: @departure_date
      )
      hash[vehicle.id] = price
    end
  end

  private
  # Write your private methods here
end
