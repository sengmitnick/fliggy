class SpecialFlightsController < ApplicationController
  before_action :set_search_params, only: [:index]

  def index
    # 获取特价机票推荐列表（模拟数据）
    @special_offers = generate_special_offers
  end

  private

  def set_search_params
    @departure_city = params[:departure_city] || '北京'
    @destination_city = params[:destination_city] || '杭州'
    @trip_type = params[:trip_type] || 'one_way'
    @departure_date = params[:departure_date] || '未来1个月'
  end

  def generate_special_offers
    # 模拟特价机票数据
    [
      {
        route: '北京→重庆',
        date: '01.21 周三',
        price: 479,
        discount: nil,
        image: 'https://images.unsplash.com/photo-1444464666168-49d633b86797?w=400'
      },
      {
        route: '北京→西安',
        date: '01.20 周二',
        price: 330,
        discount: '超低1.5折',
        image: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=400'
      },
      {
        route: '深圳→无锡',
        date: '01.20 周二',
        price: 399,
        discount: '2.2折',
        image: 'https://images.unsplash.com/photo-1541987082822-6caf72cb6c3f?w=400'
      },
      {
        route: '北京出发 可飞11城',
        date: '01.05~01.30可选',
        price: 299,
        discount: '单次低至',
        tag: '机票卡',
        image: 'https://images.unsplash.com/photo-1464037866556-6812c9d1c72e?w=400'
      },
      {
        route: '折扣盲盒特价·惊喜出发',
        date: '提前囤更省钱 未预约随时退',
        price: 199,
        discount: '单次低至',
        tag: '机票卡',
        image: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=400'
      }
    ]
  end
end
