class HomeController < ApplicationController
  include HomeDemoConcern

  def index
    # 获取用户上次选择的城市，如果没有则默认为深圳
    begin
      if session[:last_destination_slug].present?
        @current_destination = Destination.friendly.find(session[:last_destination_slug])
      else
        @current_destination = Destination.friendly.find('shen-zhen')
      end
    rescue ActiveRecord::RecordNotFound
      # 如果找不到目的地，尝试查找第一个或创建默认目的地
      @current_destination = Destination.first || Destination.create!(
        name: '深圳',
        slug: 'shen-zhen',
        description: '深圳市'
      )
    end

    # 随机搜索建议
    search_suggestions = [
      '泰国签证',
      '汉庭酒店',
      '深圳的酒店',
      '玉龙雪山',
      '郑州',
      '乐高乐园',
      '上海迪士尼',
      '三亚海滩',
      '北京故宫',
      '杭州西湖',
      '成都熊猫基地',
      '西安兵马俑',
      '桂林山水',
      '厦门鼓浪屿',
      '丽江古城',
      '张家界',
      '九寨沟',
      '黄山',
      '稻城亚丁',
      '青海湖'
    ]
    @search_placeholder = search_suggestions.sample

    @full_render = true
  end
end
