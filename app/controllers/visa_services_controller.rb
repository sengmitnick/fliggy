class VisaServicesController < ApplicationController
  def index
    @service_type = params[:service_type].presence || '全国送签'
    @urgent_only = params[:urgent_processing] == 'true'
    @country = params[:country].presence
    @sort_by = params[:sort_by].presence || 'smart'

    # 基本查询
    @visa_services = VisaService.all

    # 按服务类型筛选
    @visa_services = @visa_services.by_service_type(@service_type)

    # 加急办理筛选
    @visa_services = @visa_services.urgent_only if @urgent_only

    # 按国家筛选
    @visa_services = @visa_services.by_country(@country) if @country.present?

    # 排序
    @visa_services = case @sort_by
                     when 'price_asc'
                       @visa_services.sorted_by_price_asc
                     when 'price_desc'
                       @visa_services.sorted_by_price_desc
                     when 'sales'
                       @visa_services.sorted_by_sales
                     else
                       @visa_services.sorted_by_smart
                     end

    @visa_services = @visa_services.limit(50)
  end

  private
  # Write your private methods here
end
