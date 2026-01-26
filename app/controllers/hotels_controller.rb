class HotelsController < ApplicationController
  include CitySelectorDataConcern

  def index
    # 使用用户选择的城市（从 session 中获取），或使用参数，或默认为深圳
    if params[:city].present?
      @city = params[:city]
    elsif session[:last_destination_slug].present?
      destination = Destination.friendly.find(session[:last_destination_slug])
      @city = destination.name
    else
      @city = '深圳'
    end
    
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @star_level = params[:star_level]
    @price_min = params[:price_min]
    @price_max = params[:price_max]
    @quick_filter = params[:quick_filter]
    @hotel_type = params[:type] # hotel, homestay
    @region = params[:region]
    @location_type = params[:location_type] || 'domestic' # domestic, international
    @room_category = params[:room_category] # hourly - 用于显示钟点房
    @query = params[:q]

    @hotels = Hotel.all
    
    # 位置筛选：国内/国际
    if @location_type == 'international'
      @hotels = @hotels.international
    else
      @hotels = @hotels.domestic
    end
    
    # 城市筛选
    @hotels = @hotels.by_city(@city)
    
    # 智能区域排序：如果搜索区级城市（如"深圳市南山区"），优先显示该区的酒店
    district = extract_district(@city)
    
    # 地区筛选
    @hotels = @hotels.by_region(@region) if @region.present?
    
    # 类型筛选：酒店/民宿/钟点房
    if @room_category == 'hourly'
      # 钟点房：查询所有有钟点房的住宿场所
      @hotels = @hotels.with_hourly_rooms
    elsif @hotel_type.present?
      # 酒店或民宿：按 hotel_type 筛选
      @hotels = @hotels.by_type(@hotel_type)
    end
    
    # Apply search filter if query present
    if @query.present?
      @hotels = @hotels.where("name ILIKE ? OR address ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    
    @hotels = @hotels.by_star_level(@star_level) if @star_level.present?
    @hotels = @hotels.by_price_range(@price_min, @price_max) if @price_min.present? || @price_max.present?
    
    # 如果有区级信息，按地址匹配度排序（地址包含区名的排在前面）
    if district.present?
      @hotels = @hotels.order(
        Arel.sql("CASE WHEN address ILIKE '%#{district}%' THEN 0 ELSE 1 END"),
        :display_order, 
        created_at: :desc
      ).page(params[:page]).per(10)
    else
      @hotels = @hotels.ordered.page(params[:page]).per(10)
    end

    @featured_hotels = Hotel.featured.limit(3)
    
    # 获取搜索模态框的动态数据
    @search_modal_data = get_search_modal_data(@city)
  end

  def show
    @hotel = Hotel.find(params[:id])
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @room_category = params[:room_category] # 房型分类：overnight 或 hourly
  end

  def policy
    @hotel = Hotel.find(params[:id])
    @hotel_policy = @hotel.hotel_policy || @hotel.build_hotel_policy(default_policy_data)
  end

  def search
    # Use the same logic as index but ensure we're in search mode
    @city = params[:city] || '深圳'
    @check_in = params[:check_in].present? ? Date.parse(params[:check_in].to_s) : Time.zone.today
    @check_out = params[:check_out].present? ? Date.parse(params[:check_out].to_s) : (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @star_level = params[:star_level]
    @price_min = params[:price_min]
    @price_max = params[:price_max]
    @quick_filter = params[:quick_filter]
    @hotel_type = params[:type] # hotel, homestay
    @region = params[:region]
    @location_type = params[:location_type] || 'domestic' # domestic, international
    @room_category = params[:room_category] # hourly - 用于显示钟点房
    @query = params[:q]
    
    # NOTE: City selector data is loaded via CitySelectorDataConcern

    @hotels = Hotel.all
    
    # 位置筛选：国内/国际
    if @location_type == 'international'
      @hotels = @hotels.international
    else
      @hotels = @hotels.domestic
    end
    
    # 城市筛选
    @hotels = @hotels.by_city(@city)
    
    # 智能区域排序：如果搜索区级城市（如"深圳市南山区"），优先显示该区的酒店
    district = extract_district(@city)
    
    # 地区筛选
    @hotels = @hotels.by_region(@region) if @region.present?
    
    # 类型筛选：酒店/民宿/钟点房
    if @room_category == 'hourly'
      # 钟点房：查询所有有钟点房的住宿场所
      @hotels = @hotels.with_hourly_rooms
    elsif @hotel_type.present?
      # 酒店或民宿：按 hotel_type 筛选
      @hotels = @hotels.by_type(@hotel_type)
    end
    
    # Apply search filter if query present
    if @query.present?
      @hotels = @hotels.where("name ILIKE ? OR address ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    
    # District filtering (same as special_hotels)
    if params[:district].present?
      @hotels = @hotels.where('address LIKE ?', "%#{params[:district]}%")
    end
    
    # Price range filtering - use room category specific prices
    if params[:price_range].present?
      min_price, max_price = case params[:price_range]
      when '0-100'
        [0, 100]
      when '100-200'
        [100, 200]
      when '200-300'
        [200, 300]
      when '300+'
        [300, Float::INFINITY]
      end
      
      if min_price && max_price
        # 根据 room_category 决定筛选逻辑
        if @room_category == 'hourly'
          # 钟点房搜索：按钟点房最低价筛选
          @hotels = @hotels.where(
            id: HotelRoom.where(room_category: 'hourly')
                         .group(:hotel_id)
                         .having('MIN(price) >= ? AND MIN(price) < ?', min_price, max_price)
                         .select(:hotel_id)
          )
        else
          # 默认/整晚搜索：按整晚房最低价筛选
          @hotels = @hotels.where(
            id: HotelRoom.where(room_category: 'overnight')
                         .group(:hotel_id)
                         .having('MIN(price) >= ? AND MIN(price) < ?', min_price, max_price)
                         .select(:hotel_id)
          )
        end
      end
    end
    
    @hotels = @hotels.by_star_level(@star_level) if @star_level.present?
    @hotels = @hotels.by_price_range(@price_min, @price_max) if @price_min.present? || @price_max.present?
    
    # Sorting (updated to match special_hotels pattern)
    case params[:sort]
    when 'rating'
      @hotels = @hotels.order(rating: :desc, price: :asc)
    when 'distance'
      @hotels = @hotels.order(distance: :asc, price: :asc)
    when 'price'
      @hotels = @hotels.order(price: :asc)
    else
      # 如果有区级信息，按地址匹配度排序（地址包含区名的排在前面）
      if district.present?
        @hotels = @hotels.order(
          Arel.sql("CASE WHEN address ILIKE '%#{district}%' THEN 0 ELSE 1 END"),
          :display_order, 
          created_at: :desc
        )
      else
        @hotels = @hotels.ordered
      end
    end
    
    @hotels = @hotels.page(params[:page]).per(10)

    @featured_hotels = Hotel.featured.limit(3)
    
    # 获取搜索模态框的动态数据
    @search_modal_data = get_search_modal_data(@city)
    
    # Extract districts for filter bar
    @districts = extract_districts_from_hotels(@city)
    
    # Render the dedicated search results view
    render :search
  end

  def map
    # Map view for hotels in a specific city/region
    @city = params[:city] || '深圳'
    @check_in = params[:check_in].present? ? Date.parse(params[:check_in].to_s) : Time.zone.today
    @check_out = params[:check_out].present? ? Date.parse(params[:check_out].to_s) : (Time.zone.today + 1.day)
    @rooms = params[:rooms]&.to_i || 1
    @adults = params[:adults]&.to_i || 1
    @children = params[:children]&.to_i || 0
    @location_type = params[:location_type] || 'domestic'
    
    @hotels = Hotel.all
    
    # Filter by location type
    if @location_type == 'international'
      @hotels = @hotels.international
    else
      @hotels = @hotels.domestic
    end
    
    # Filter by city
    @hotels = @hotels.by_city(@city)
    
    # Load all hotels for map (no pagination)
    @hotels = @hotels.ordered.limit(100)
    
    render :map
  end

  private
  
  # 从城市名称中提取区级信息
  # 例如："深圳市南山区" -> "南山区"
  def extract_district(city)
    return nil if city.blank?
    # 匹配格式：XX市YY区
    match = city.match(/市(.+区)$/)
    match ? match[1] : nil
  end
  
  def default_policy_data
    {
      check_in_time: "15:00后",
      check_out_time: "12:00前",
      pet_policy: "暂不支持携带宠物和服务型宠物，感谢理解",
      breakfast_type: "其他",
      breakfast_hours: "每天07:00-10:00",
      breakfast_price: 44,
      payment_methods: ["银联", "支付宝"]
    }
  end
  
  # 根据城市获取搜索模态框的动态数据（包含9个分类）
  def get_search_modal_data(city)
    return default_search_modal_data if city.blank?
    
    # 移除"市"字符以获取基础城市名
    base_city = city.gsub(/市.*$/, '')
    
    # 获取该城市实际存在的酒店品牌（基于酒店名称）
    actual_brands = get_actual_hotel_brands(city)
    
    # 城市数据映射表（景点/医院/大学等保持静态，品牌动态生成）
    city_data = {
      '深圳' => {
        hot_searches: ['深圳北站', '宝安机场', '深圳湾', '华强北', '罗湖口岸', '福田口岸', '世界之窗', '欢乐谷'],
        hot_locations: ['宝安机场商圈', '罗湖商圈', '福田商圈', '南山商圈', '深圳湾商圈', '华强北商圈', '蛇口商圈', '龙岗商圈'],
        metro: ['深圳北站', '福田站', '罗湖站', '会展中心站', '市民中心站', '车公庙站', '科学馆站', '大剧院站'],
        airport: ['宝安国际机场', '深圳北站', '深圳站', '福田站', '宝安机场T3航站楼', '深圳东站', '深圳西站', '深圳北站'],
        attraction: ['世界之窗', '欢乐谷', '深圳湾公园', '东部华侨城', '大梅沙', '小梅沙', '莲花山公园', '深圳野生动物园'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '海景房'],
        hospital: ['北京大学深圳医院', '深圳市人民医院', '深圳市第二人民医院', '南方医科大学深圳医院', '深圳市儿童医院', '深圳市中医院', '香港大学深圳医院', '深圳市妇幼保健院'],
        university: ['深圳大学', '南方科技大学', '深圳技术大学', '香港中文大学（深圳）', '哈尔滨工业大学（深圳）', '中山大学（深圳）', '北京大学深圳研究生院', '清华大学深圳国际研究生院']
      },
      '北京' => {
        hot_searches: ['北京西站', '天安门', '故宫', '首都机场', '北京南站', '王府井', '三里屯', '国贸'],
        hot_locations: ['首都机场商圈', '王府井商圈', '国贸商圈', '三里屯商圈', '中关村', '西单商圈', '金融街', '望京'],
        metro: ['国贸站', '三里屯站', '王府井站', '西单站', '天安门东站', '中关村站', '朝阳门站', '建国门站'],
        airport: ['首都国际机场', '北京大兴国际机场', '北京西站', '北京南站', '北京站', '北京北站', '首都机场T3航站楼', '大兴机场'],
        attraction: ['天安门广场', '故宫', '天坛', '颐和园', '长城', '鸟巢', '水立方', '圆明园'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '四合院'],
        hospital: ['北京协和医院', '北京大学第一医院', '中国人民解放军总医院', '北京同仁医院', '北京天坛医院', '北京儿童医院', '北京安贞医院', '北京朝阳医院'],
        university: ['北京大学', '清华大学', '中国人民大学', '北京师范大学', '北京航空航天大学', '北京理工大学', '中国农业大学', '北京外国语大学']
      },
      '上海' => {
        hot_searches: ['外滩', '浦东机场', '虹桥火车站', '东方明珠', '南京路', '人民广场', '陆家嘴', '迪士尼'],
        hot_locations: ['浦东机场商圈', '虹桥商圈', '人民广场商圈', '南京路商圈', '陆家嘴商圈', '外滩', '静安寺商圈', '徐家汇商圈'],
        metro: ['人民广场站', '陆家嘴站', '南京东路站', '静安寺站', '徐家汇站', '虹桥火车站', '上海火车站', '世纪大道站'],
        airport: ['浦东国际机场', '虹桥国际机场', '上海虹桥站', '上海站', '上海南站', '浦东机场T1航站楼', '浦东机场T2航站楼', '虹桥火车站'],
        attraction: ['外滩', '东方明珠', '上海迪士尼', '南京路步行街', '豫园', '田子坊', '新天地', '上海中心大厦'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '江景房'],
        hospital: ['上海交通大学医学院附属瑞金医院', '复旦大学附属华山医院', '上海市第一人民医院', '上海儿童医学中心', '上海中山医院', '上海市第六人民医院', '上海市肺科医院', '上海市第九人民医院'],
        university: ['复旦大学', '上海交通大学', '同济大学', '华东师范大学', '上海财经大学', '华东理工大学', '上海大学', '东华大学']
      },
      '广州' => {
        hot_searches: ['广州塔', '白云机场', '珠江新城', '广州南站', '北京路', '天河城', '上下九', '长隆'],
        hot_locations: ['白云机场商圈', '珠江新城商圈', '天河城商圈', '北京路商圈', '上下九商圈', '广州塔商圈', '琶洲会展中心', '长隆商圈'],
        metro: ['珠江新城站', '广州塔站', '天河客运站', '体育西路站', '北京路站', '公园前站', '客村站', '广州南站'],
        airport: ['白云国际机场', '广州南站', '广州站', '广州东站', '广州北站', '白云机场T1航站楼', '白云机场T2航站楼', '广州南站'],
        attraction: ['广州塔', '长隆欢乐世界', '珠江夜游', '白云山', '陈家祠', '沙面', '越秀公园', '广州动物园'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '江景房'],
        hospital: ['中山大学附属第一医院', '广东省人民医院', '南方医科大学南方医院', '广州市第一人民医院', '广东省中医院', '广州市妇女儿童医疗中心', '中山大学孙逸仙纪念医院', '广州医科大学附属第一医院'],
        university: ['中山大学', '华南理工大学', '暨南大学', '华南师范大学', '广东工业大学', '广州大学', '华南农业大学', '广东外语外贸大学']
      },
      '杭州' => {
        hot_searches: ['西湖', '萧山机场', '西溪湿地', '雷峰塔', '杭州东站', '武林广场', '钱江新城', '河坊街'],
        hot_locations: ['西湖景区', '武林广场商圈', '钱江新城商圈', '萧山机场商圈', '西溪湿地商圈', '河坊街商圈', '滨江高教园区', '城西银泰城'],
        metro: ['西湖文化广场站', '武林广场站', '钱江路站', '火车东站', '定安路站', '近江站', '滨和路站', '市民中心站'],
        airport: ['杭州萧山国际机场', '杭州东站', '杭州站', '杭州南站', '杭州城站', '萧山机场T1航站楼', '萧山机场T2航站楼', '杭州东站'],
        attraction: ['西湖', '雷峰塔', '灵隐寺', '西溪湿地', '宋城', '千岛湖', '河坊街', '钱塘江'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '湖景房'],
        hospital: ['浙江大学医学院附属第一医院', '浙江大学医学院附属第二医院', '浙江省人民医院', '杭州市第一人民医院', '浙江省中医院', '浙江大学医学院附属儿童医院', '浙江省肿瘤医院', '杭州市中医院'],
        university: ['浙江大学', '杭州电子科技大学', '浙江工业大学', '浙江理工大学', '杭州师范大学', '中国美术学院', '浙江工商大学', '浙江财经大学']
      },
      '成都' => {
        hot_searches: ['春熙路', '双流机场', '宽窄巷子', '成都东站', '太古里', '锦里', '天府广场', '熊猫基地'],
        hot_locations: ['春熙路商圈', '太古里商圈', '天府广场商圈', '宽窄巷子商圈', '双流机场商圈', '锦里商圈', '金融城商圈', '高新区'],
        metro: ['春熙路站', '天府广场站', '骡马市站', '火车南站', '火车东站', '太古里站', '金融城站', '世纪城站'],
        airport: ['成都双流国际机场', '成都天府国际机场', '成都东站', '成都站', '成都南站', '双流机场T1航站楼', '双流机场T2航站楼', '天府机场T1航站楼'],
        attraction: ['武侯祠', '锦里', '宽窄巷子', '大熊猫繁育研究基地', '都江堰', '青城山', '杜甫草堂', '金沙遗址'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '温泉酒店'],
        hospital: ['四川大学华西医院', '四川省人民医院', '成都市第一人民医院', '成都市第二人民医院', '成都市第三人民医院', '成都市妇女儿童中心医院', '四川省肿瘤医院', '成都中医药大学附属医院'],
        university: ['四川大学', '电子科技大学', '西南交通大学', '西南财经大学', '四川师范大学', '成都理工大学', '西南石油大学', '成都中医药大学']
      },
      '西安' => {
        hot_searches: ['钟楼', '西安北站', '兵马俑', '大雁塔', '回民街', '大唐芙蓉园', '华清池', '城墙'],
        hot_locations: ['钟楼商圈', '小寨商圈', '高新区', '曲江新区', '大雁塔商圈', '城墙商圈', '回民街商圈', '咸阳机场商圈'],
        metro: ['钟楼站', '小寨站', '大雁塔站', '北大街站', '五路口站', '火车站', '行政中心站', '韦曲南站'],
        airport: ['西安咸阳国际机场', '西安北站', '西安站', '西安南站', '咸阳机场T1航站楼', '咸阳机场T2航站楼', '咸阳机场T3航站楼', '西安北站'],
        attraction: ['兵马俑', '大雁塔', '钟楼', '鼓楼', '城墙', '回民街', '大唐芙蓉园', '华清池'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '温泉酒店'],
        hospital: ['西安交通大学第一附属医院', '西安交通大学第二附属医院', '陕西省人民医院', '西安市中心医院', '西北妇女儿童医院', '第四军医大学西京医院', '第四军医大学唐都医院', '陕西省中医院'],
        university: ['西安交通大学', '西北工业大学', '西安电子科技大学', '陕西师范大学', '长安大学', '西北大学', '西安理工大学', '西安建筑科技大学']
      },
      '南京' => {
        hot_searches: ['新街口', '南京南站', '夫子庙', '中山陵', '玄武湖', '总统府', '南京站', '禄口机场'],
        hot_locations: ['新街口商圈', '夫子庙商圈', '河西万达商圈', '江宁万达商圈', '禄口机场商圈', '南京南站商圈', '玄武湖商圈', '鼓楼商圈'],
        metro: ['新街口站', '夫子庙站', '南京南站', '南京站', '河西万达站', '仙林中心站', '新模范马路站', '玄武门站'],
        airport: ['南京禄口国际机场', '南京南站', '南京站', '南京东站', '禄口机场T1航站楼', '禄口机场T2航站楼', '南京南站', '南京北站'],
        attraction: ['中山陵', '夫子庙', '总统府', '玄武湖', '明孝陵', '秦淮河', '南京博物院', '牛首山'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '湖景房'],
        hospital: ['南京鼓楼医院', '江苏省人民医院', '东南大学附属中大医院', '南京市第一医院', '南京儿童医院', '南京市中医院', '江苏省中医院', '南京脑科医院'],
        university: ['南京大学', '东南大学', '南京航空航天大学', '南京理工大学', '河海大学', '南京师范大学', '南京农业大学', '中国药科大学']
      },
      '武汉' => {
        hot_searches: ['武汉站', '光谷', '江汉路', '户部巷', '黄鹤楼', '武汉大学', '东湖', '汉口'],
        hot_locations: ['光谷商圈', '江汉路商圈', '楚河汉街商圈', '武汉天地商圈', '黄鹤楼商圈', '户部巷商圈', '东湖商圈', '武广商圈'],
        metro: ['光谷广场站', '江汉路站', '武汉站', '汉口站', '楚河汉街站', '街道口站', '中南路站', '武昌火车站'],
        airport: ['武汉天河国际机场', '武汉站', '汉口站', '武昌站', '天河机场T1航站楼', '天河机场T2航站楼', '天河机场T3航站楼', '武汉站'],
        attraction: ['黄鹤楼', '东湖', '武汉大学', '户部巷', '楚河汉街', '武汉长江大桥', '汉口江滩', '归元禅寺'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '江景房'],
        hospital: ['华中科技大学同济医学院附属同济医院', '华中科技大学同济医学院附属协和医院', '武汉大学人民医院', '武汉大学中南医院', '湖北省人民医院', '武汉市中心医院', '武汉儿童医院', '武汉市第一医院'],
        university: ['武汉大学', '华中科技大学', '华中师范大学', '武汉理工大学', '中国地质大学', '华中农业大学', '中南财经政法大学', '湖北大学']
      },
      '重庆' => {
        hot_searches: ['解放碑', '洪崖洞', '磁器口', '重庆北站', '江北机场', '观音桥', '南坪', '李子坝'],
        hot_locations: ['解放碑商圈', '观音桥商圈', '南坪商圈', '沙坪坝商圈', '江北嘴商圈', '洪崖洞商圈', '磁器口商圈', '江北机场商圈'],
        metro: ['解放碑站', '观音桥站', '南坪站', '沙坪坝站', '红旗河沟站', '江北机场站', '重庆北站', '两路口站'],
        airport: ['重庆江北国际机场', '重庆北站', '重庆西站', '重庆站', '江北机场T2航站楼', '江北机场T3航站楼', '重庆北站南广场', '重庆北站北广场'],
        attraction: ['解放碑', '洪崖洞', '磁器口', '长江索道', '武隆天生三桥', '大足石刻', '南山一棵树', '李子坝轻轨站'],
        theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '江景房'],
        hospital: ['重庆医科大学附属第一医院', '重庆医科大学附属第二医院', '重庆医科大学附属儿童医院', '重庆市人民医院', '重庆新桥医院', '重庆西南医院', '重庆大坪医院', '重庆市中医院'],
        university: ['重庆大学', '西南大学', '重庆邮电大学', '重庆交通大学', '西南政法大学', '重庆医科大学', '四川外国语大学', '重庆师范大学']
      }
    }
    
    # 获取对应城市的数据，如果没有则返回默认数据
    result = city_data[base_city] || default_search_modal_data
    
    # 将品牌部分替换为实际存在的品牌
    result[:hot_brands] = actual_brands.any? ? actual_brands : result.fetch(:hot_brands, ['希尔顿', '万豪', '亚朵'])
    
    result
  end
  
  # 获取该城市实际存在的酒店品牌（基于酒店名称提取品牌）
  def get_actual_hotel_brands(city)
    return [] if city.blank?
    
    # 常见品牌关键词列表
    brand_keywords = ['希尔顿', '万豪', '万丽', '凯悦', '雅高', '香格里拉', '洲际', '喜来登', 
                      '威斯汀', '丽思卡尔顿', '亚朵', '全季', '维也纳', '如家', '汉庭', 
                      '锦江', '华住', '格林', '7天', '桔子', '山海居', '菲住']
    
    # 获取该城市所有酒店名称
    hotel_names = Hotel.by_city(city).pluck(:name)
    
    # 提取品牌（检查酒店名称中是否包含品牌关键词）
    brands = []
    brand_keywords.each do |keyword|
      if hotel_names.any? { |name| name.include?(keyword) }
        brands << keyword
      end
    end
    
    # 返回前8个品牌，如果不足8个则返回全部
    brands.take(8)
  end
  
  # 默认搜索模态框数据
  def default_search_modal_data
    {
      hot_searches: ['火车站', '机场', '市中心', '商业区', '景区', '会展中心', '汽车站', '体育馆'],
      hot_brands: ['希尔顿花园', '万丽', '菲住', '万豪', '希尔顿', '亚朵', '全季', '维也纳'],
      hot_locations: ['机场商圈', '火车站商圈', '市中心商圈', '商业区', '景区商圈', '会展中心商圈', '高新区', '大学城'],
      metro: ['火车站', '市中心站', '商业街站', '体育中心站', '展览中心站', '大学城站', '科技园站', '政务中心站'],
      airport: ['机场', '火车站', '高铁站', '汽车站', '机场T1航站楼', '机场T2航站楼', '长途客运站', '城际铁路站'],
      attraction: ['博物馆', '文化中心', '公园', '广场', '纪念馆', '展览馆', '体育馆', '会展中心'],
      theme: ['酒店', '电竞酒店', '公寓', '电竞房', '麻将房', '亲子酒店', '别墅', '度假酒店'],
      hospital: ['市人民医院', '市中心医院', '市第一人民医院', '市第二人民医院', '市中医院', '市儿童医院', '市妇幼保健院', '中医院'],
      university: ['综合大学', '理工大学', '师范大学', '医科大学', '财经大学', '科技大学', '外国语大学', '职业技术学院']
    }
  end
  
  # Extract districts from hotel addresses for filter bar
  def extract_districts_from_hotels(city)
    addresses = Hotel.by_city(city).pluck(:address).compact
    districts = addresses.map do |address|
      if address.match?(/（\w+区）/)
        address.match(/（\w+区）/)[1]
      elsif address.match?(/（\w+新区）/)
        address.match(/（\w+新区）/)[1]
      else
        address.split(/[路街道号]/).first
      end
    end.compact.uniq.sort
    districts
  end
end
