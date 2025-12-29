class Admin::DeepTravelGuidesController < Admin::BaseController
  before_action :set_deep_travel_guide, only: [:show, :edit, :update, :destroy]

  def index
    @deep_travel_guides = DeepTravelGuide.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @deep_travel_guide = DeepTravelGuide.new
  end

  def create
    @deep_travel_guide = DeepTravelGuide.new(deep_travel_guide_params)

    if @deep_travel_guide.save
      redirect_to admin_deep_travel_guide_path(@deep_travel_guide), notice: 'Deep travel guide was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deep_travel_guide.update(deep_travel_guide_params)
      redirect_to admin_deep_travel_guide_path(@deep_travel_guide), notice: 'Deep travel guide was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deep_travel_guide.destroy
    redirect_to admin_deep_travel_guides_path, notice: 'Deep travel guide was successfully deleted.'
  end

  private

  def set_deep_travel_guide
    @deep_travel_guide = DeepTravelGuide.find(params[:id])
  end

  def deep_travel_guide_params
    params.require(:deep_travel_guide).permit(:name, :title, :description, :follower_count, :experience_years, :specialties, :price, :served_count, :rank, :rating, :featured, :avatar, :video)
  end
end
