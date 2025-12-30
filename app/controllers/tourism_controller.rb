class TourismController < ApplicationController
  def index
    # 默认城市：广州（匹配新设计）
    @current_city = params[:city].presence || '广州'
    
    # 热门搜索
    @hot_searches = [
      { name: '长白山风景区', count: '9.3万人感兴趣' },
      { name: '深圳', count: '296万+人想去' }
    ]
    
    # 旅游分类 - 金刚区数据
    @tour_categories = {
      main: [
        { name: '跟团游', icon: 'tourism/跟团游.png', style: 'gradient-red' },
        { name: '自由行', icon: 'tourism/自由行.png', style: 'gradient-blue' }
      ],
      grid_row1: [
        { name: '精品小团', icon: 'tourism/精品小团.png' },
        { name: '私家团', icon: 'tourism/私家团.png' },
        { name: '一日游', icon: 'tourism/一日游.png' },
        { name: '定制游', icon: 'tourism/定制游.png' },
        { name: '邮轮游', icon: 'tourism/邮轮游.png' }
      ],
      grid_row2: [
        { name: '机酒套餐', icon: 'tourism/机酒套餐.png' },
        { name: '包车游', icon: 'tourism/包车游.png' },
        { name: '景酒套餐', icon: 'tourism/景酒套餐.png' },
        { name: '门票', icon: 'tourism/门票.png', badge: '特惠' },
        { name: '深度旅行+', icon: 'tourism/深度旅行.png' }
      ],
      grid_row3: [
        { name: '签证', icon: 'tourism/签证.png', badge: '出签率高' },
        { name: '境外上网', icon: 'tourism/境外上网.png' },
        { name: '境外交通', icon: 'tourism/境外交通.png' }
      ]
    }
    
    # 城市标签
    @city_tabs = ['北京', '上海', '杭州', '惠州', '中国香港', '珠海']
    
    # 广州景点热榜
    @hot_attractions = [
      {
        name: '广州长隆旅游度假区',
        price: '¥98起',
        sales: '已售1000+',
        image: 'tourism/景点热榜左.png',
        rank: 'TOP1'
      },
      {
        name: '广州长隆野生动物...',
        price: '¥292.8起',
        sales: '',
        image: 'tourism/景点热榜右.png',
        rank: 'TOP2'
      }
    ]
    
    # 特色体验
    @experiences = [
      { name: '博物馆讲解', type: 'custom', color: 'blue' },
      { name: '逛乐园', image: 'tourism/逛乐园.png' },
      { name: '动物园', image: 'tourism/动物园.png' },
      { name: '城市地标', image: 'tourism/美术馆.png' }
    ]
    
    # 优选商家
    @featured_merchants = [
      {
        name: '潮州大航国旅专营店',
        specialty: '广东一日游',
        served: '2000+'
      },
      {
        name: '汕头趣游旅游专营店',
        specialty: '广东一日游',
        served: '500+'
      }
    ]
    
    # 大家都在买
    @popular_products = [
      {
        title: '飞猪冰雪温泉季',
        badge: '领最高100元冰雪补贴',
        type: 'promotion'
      },
      {
        title: '已售10万+云南旅游丽江包车滇藏泸沽湖大理香...',
        price: '¥100起',
        sales: '已售2万+',
        tag: '旅游包车',
        image: 'tourism/包车游.png'
      }
    ]
  end
  
  def search
    @query = params[:q]
    # TODO: 实现搜索功能
    redirect_to tourism_index_path, notice: "搜索功能开发中..."
  end
end
