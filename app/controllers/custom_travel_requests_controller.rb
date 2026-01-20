class CustomTravelRequestsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create]

  def my_orders
    @custom_travel_requests = current_user.custom_travel_requests.order(created_at: :desc)
  end

  def show
    @custom_travel_request = current_user.custom_travel_requests.find(params[:id])
  end

  def cancel
    @custom_travel_request = current_user.custom_travel_requests.find(params[:id])
    
    if @custom_travel_request.update(status: :cancelled)
      redirect_to custom_travel_request_path(@custom_travel_request), notice: '订单已取消'
    else
      redirect_to custom_travel_request_path(@custom_travel_request), alert: '取消失败，请重试'
    end
  end

  def create
    @custom_travel_request = current_user.custom_travel_requests.build(custom_travel_request_params)
    
    if @custom_travel_request.save
      # Use status: :see_other for Turbo to follow the redirect properly
      redirect_to custom_travel_request_path(@custom_travel_request), status: :see_other
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
