class TourismController < ApplicationController
  def index
    # 默认城市：深圳
    @current_city = params[:city].presence || '深圳'
    
    # 热门城市
    @hot_cities = [
      { name: '长白山风景区', count: '9.3万人感兴趣' },
      { name: '深圳', count: '295万+人想去' },
      { name: '广州', count: '593万+人想去' },
      { name: '北京', count: '501万+人想去' }
    ]
    
    # 旅游分类
    @tour_categories = [
      { name: '跟团游', icon: 'tourism/跟团游.png', badge: nil },
      { name: '精品小团', icon: 'tourism/精品小团.png', badge: nil },
      { name: '私家团', icon: 'tourism/私家团.png', badge: nil },
      { name: '一日游', icon: 'tourism/一日游.png', badge: nil },
      { name: '定制游', icon: 'tourism/定制游.png', badge: nil },
      { name: '邮轮游', icon: 'tourism/邮轮游.png', badge: nil },
      { name: '机酒套餐', icon: 'tourism/机酒套餐.png', badge: nil },
      { name: '包车游', icon: 'tourism/包车游.png', badge: nil },
      { name: '景酒套餐', icon: 'tourism/景酒套餐.png', badge: nil },
      { name: '门票', icon: 'tourism/门票.png', badge: nil },
      { name: '深度旅行+', icon: 'tourism/深度旅行.png', badge: '特惠' },
      { name: '签证', icon: 'tourism/签证.png', badge: '出签率高' },
      { name: '境外上网', icon: 'tourism/境外上网.png', badge: nil },
      { name: '境外交通', icon: 'tourism/境外交通.png', badge: nil }
    ]
    
    # 自由行分类
    @free_tour_categories = [
      { name: '自由行', icon: 'tourism/自由行.png' }
    ]
    
    # 特色标签
    @feature_tags = [
      { name: '特色火车', icon: 'tourism/特色火车.png' },
      { name: '逛乐园', icon: 'tourism/逛乐园.png' },
      { name: '动物园', icon: 'tourism/动物园.png' },
      { name: '美术馆', icon: 'tourism/美术馆.png' }
    ]
    
    # 城市列表
    @cities = City.all.order(:pinyin).limit(20) rescue []
    
    # 推荐内容
    @hot_attractions = [
      {
        name: '华发冰雪热雪奇迹',
        price: '¥339起',
        sales: '已售1000+',
        image: 'tourism/景点热榜左.png'
      },
      {
        name: '深圳小梅沙海洋世界',
        price: '¥220.92起',
        sales: '已售6000+',
        image: 'tourism/景点热榜左.png'
      },
      {
        name: '深圳野生动物园',
        price: '¥180起',
        sales: '已售5000+',
        image: 'tourism/景点热榜左.png'
      }
    ]
    
    @experiences = [
      { name: '逛乐园', image: 'tourism/逛乐园.png' },
      { name: '出海', image: nil },
      { name: '动物园', image: 'tourism/动物园.png' },
      { name: '观星', image: nil }
    ]
  end
  
  def search
    @query = params[:q]
    # TODO: 实现搜索功能
    redirect_to tourism_index_path, notice: "搜索功能开发中..."
  end
end
