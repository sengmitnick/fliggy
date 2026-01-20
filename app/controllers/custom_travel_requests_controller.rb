class CustomTravelRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @custom_travel_request = CustomTravelRequest.new(custom_travel_request_params)
    
    if @custom_travel_request.save
      # 成功后返回Turbo Stream响应
      render turbo_stream: turbo_stream.replace(
        'custom-travel-modal',
        partial: 'custom_travel_requests/success',
        locals: { request: @custom_travel_request }
      )
    else
      # 失败后返回错误信息
      render turbo_stream: turbo_stream.replace(
        'custom-travel-modal',
        partial: 'shared/custom_travel_modal',
        locals: { errors: @custom_travel_request.errors }
      ), status: :unprocessable_entity
    end
  end

  private

  def custom_travel_request_params
    params.require(:custom_travel_request).permit(
      :departure_city,
      :destination_city,
      :adults_count,
      :children_count,
      :elders_count,
      :departure_date,
      :days_count,
      :preferences,
      :phone,
      :expected_merchants,
      :contact_time
    )
  end
end
