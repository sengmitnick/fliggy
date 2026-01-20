# frozen_string_literal: true

module CitySelectorDataConcern
  extend ActiveSupport::Concern

  included do
    before_action :load_city_selector_data, if: -> { needs_city_selector? }
  end

  private

  # 加载城市选择器所需的数据
  def load_city_selector_data
    # 国际地区列表
    international_regions = %w[日本 韩国 泰国 马来西亚 新加坡 越南 英国 法国 意大利 西班牙 荷兰 德国 美国 加拿大 澳大利亚 新西兰 阿联酋 土耳其 埃及 肯尼亚]

    # 热门城市（国内）
    @hot_cities = City.where.not(region: international_regions)
                     .where(is_hot: true)
                     .order(:pinyin)

    # 所有国内城市
    @all_cities = City.where.not(region: international_regions)
                     .order(:pinyin)
  end

  # 判断当前控制器/动作是否需要城市选择器数据
  def needs_city_selector?
    true
  end
end
