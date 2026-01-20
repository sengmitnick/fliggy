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

    # 热门城市（国内）- 返回城市名称数组
    @hot_domestic_cities = City.where.not(region: international_regions)
                               .where(is_hot: true)
                               .order(:pinyin)
                               .pluck(:name)

    # 所有国内城市按首字母分组 - 确保先加载所有记录
    domestic_cities = City.where.not(region: international_regions)
                          .order(:pinyin)
                          .to_a  # Load all records first
    
    @cities_by_letter = domestic_cities.group_by { |city| city.pinyin.first.upcase }
                                      .transform_values { |cities| cities.map(&:name) }

    # 国际城市按地区分组（城市名, 国家）- 确保先加载所有记录
    international_cities = City.where(region: international_regions)
                              .order(:pinyin)
                              .to_a  # Load all records first
    
    # 使用 select 而非 where 来过滤已加载的数组
    @international_cities_by_region = {
      '热门城市' => international_cities.select { |c| c.is_hot }.map { |c| [c.name, c.region] },
      '东南亚' => international_cities.select { |c| %w[泰国 马来西亚 新加坡 越南].include?(c.region) }.map { |c| [c.name, c.region] },
      '日韩' => international_cities.select { |c| %w[日本 韩国].include?(c.region) }.map { |c| [c.name, c.region] },
      '欧洲' => international_cities.select { |c| %w[英国 法国 意大利 西班牙 荷兰 德国].include?(c.region) }.map { |c| [c.name, c.region] },
      '美洲' => international_cities.select { |c| %w[美国 加拿大].include?(c.region) }.map { |c| [c.name, c.region] },
      '大洋洲' => international_cities.select { |c| %w[澳大利亚 新西兰].include?(c.region) }.map { |c| [c.name, c.region] },
      '中东非洲' => international_cities.select { |c| %w[阿联酋 土耳其 埃及 肯尼亚].include?(c.region) }.map { |c| [c.name, c.region] }
    }
  end

  # 判断当前控制器/动作是否需要城市选择器数据
  def needs_city_selector?
    true
  end
end
