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
    @destination = params[:destination]
    # TODO: Implement search functionality
    redirect_to tour_groups_path(destination: @destination), notice: "搜索功能开发中..."
  end
end
