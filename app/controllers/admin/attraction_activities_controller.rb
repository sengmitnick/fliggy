class Admin::AttractionActivitiesController < Admin::BaseController
  before_action :set_attraction_activity, only: [:show, :edit, :update, :destroy]

  def index
    @attraction_activities = AttractionActivity.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @attraction_activity = AttractionActivity.new
  end

  def create
    @attraction_activity = AttractionActivity.new(attraction_activity_params)

    if @attraction_activity.save
      redirect_to admin_attraction_activity_path(@attraction_activity), notice: 'Attraction activity was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @attraction_activity.update(attraction_activity_params)
      redirect_to admin_attraction_activity_path(@attraction_activity), notice: 'Attraction activity was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attraction_activity.destroy
    redirect_to admin_attraction_activities_path, notice: 'Attraction activity was successfully deleted.'
  end

  private

  def set_attraction_activity
    @attraction_activity = AttractionActivity.find(params[:id])
  end

  def attraction_activity_params
    params.require(:attraction_activity).permit(:name, :activity_type, :original_price, :current_price, :discount_info, :refund_policy, :description, :duration, :sales_count, :attraction_id, :image)
  end
end
