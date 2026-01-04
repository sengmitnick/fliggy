class TourGroupsController < ApplicationController
  def index
    # Default destination
    @destination = params[:destination].presence || '上海'
    
    # Hot destinations
    @hot_destinations = ['上海', '北京', '杭州', '广州', '成都']
    
    # Duration options
    @duration_options = [
      { label: '一日游', value: '1' },
      { label: '2天', value: '2', hot: true },
      { label: '3天', value: '3', hot: true }
    ]
    
    # Group size options
    @group_size_options = [
      { label: '大团', description: '15人以上', value: 'large' },
      { label: '小团', description: '最多15人', value: 'small' }
    ]
    
    # Tour recommendations
    @tour_recommendations = [
      {
        image: 'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=500',
        badge: '跟团游',
        title: '泗水巴厘省 巴厘岛佩尼达岛 6天5晚 6人小团',
        price: '¥3399起',
        sales: '已售15'
      },
      {
        image: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=500',
        badge: '一日游',
        title: '七加旅行普吉岛出海一日游皇帝岛珊瑚',
        price: '¥168起',
        sales: '已售1万+'
      },
      {
        image: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
        badge: '跟团游',
        title: '丽江大理 玉龙雪山大理古城 5天',
        price: '¥1799起',
        sales: ''
      }
    ]
  end
  
  def search
    @destination = params[:destination].presence || '上海'
    @active_tab = params[:tab].presence || 'group_tour'  # 默认选中跟团游
    
    # Search results - 示例数据（增加更多数据以测试滚动效果）
    base_results = [
      {
        image: 'https://images.unsplash.com/photo-1464037866556-6812c9d1c72e?w=600',
        badge: '一日游',
        departure: '上海出发',
        title: '上海+上海天文馆+一日游+随时可定+上午下午场大咖讲解',
        rating: 4.9,
        rating_desc: '讲解生动，孩子爱听',
        highlights: ['上海天文馆', '研学'],
        tags: ['可订明日', '无自费', '纯玩无购物'],
        provider: '天津梦远旅行社专营店',
        sales: '已售9000+',
        price: '68',
        price_suffix: '起'
      },
      {
        image: 'https://images.unsplash.com/photo-1550592704-6c76defa9985?w=600',
        badge: '一日游',
        departure: nil,
        title: '上海+上海科技馆+一日游+快速出票+大咖讲解+精品小团',
        rating: nil,
        rating_desc: nil,
        highlights: ['无购物', '无自费'],
        tags: ['无自费', '无购物'],
        provider: '北京趣发现旅行社专营店',
        sales: '已售7',
        price: '25',
        price_suffix: '起'
      },
      {
        image: 'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=600',
        badge: '一日游',
        departure: '上海出发',
        title: '上海+东方明珠/城市历史发展陈列馆/外滩+一日游+观魔都美景历史...',
        rating: 4.9,
        rating_desc: '东方明珠美景入画来',
        highlights: ['外滩', '上海城市历史发展陈列馆', '东方明珠'],
        tags: ['可订今日', '无自费', '纯玩无购物', '支持改期'],
        provider: '江苏五方旅行社',
        sales: '已售1000+',
        price: '109',
        price_suffix: '起'
      },
      {
        image: 'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=600',
        badge: '跟团游',
        departure: '上海出发',
        title: '上海+迪士尼乐园+2日游+含门票+精选酒店+往返接送',
        rating: 4.8,
        rating_desc: '迪士尼梦幻之旅',
        highlights: ['迪士尼乐园', '含门票', '接送服务'],
        tags: ['可订明日', '含酒店', '含门票'],
        provider: '上海春秋旅行社',
        sales: '已售5000+',
        price: '899',
        price_suffix: '起'
      },
      {
        image: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
        badge: '一日游',
        departure: '上海出发',
        title: '上海+朱家角古镇+一日游+纯玩无购物+含午餐',
        rating: 4.7,
        rating_desc: '古镇风情浓郁',
        highlights: ['朱家角古镇', '江南水乡', '含午餐'],
        tags: ['纯玩无购物', '无自费', '含餐'],
        provider: '携程旅行专营店',
        sales: '已售3000+',
        price: '128',
        price_suffix: '起'
      },
      {
        image: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
        badge: '跟团游',
        departure: '上海出发',
        title: '上海+苏州+杭州+3日游+经典江南三城+含住宿',
        rating: 4.9,
        rating_desc: '江南美景尽收眼底',
        highlights: ['苏州园林', '西湖', '乌镇'],
        tags: ['精品小团', '含酒店', '纯玩'],
        provider: '杭州携程国际旅行社',
        sales: '已售8000+',
        price: '1299',
        price_suffix: '起'
      }
    ]
    
    # 复制3次以确保有足够内容产生滚动
    @search_results = base_results * 3
  end
end
