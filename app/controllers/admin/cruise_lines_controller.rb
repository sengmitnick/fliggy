class Admin::CruiseLinesController < Admin::BaseController
  before_action :set_cruise_line, only: [:show, :edit, :update, :destroy]

  def index
    @cruise_lines = CruiseLine.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @cruise_line = CruiseLine.new
  end

  def create
    @cruise_line = CruiseLine.new(cruise_line_params)

    if @cruise_line.save
      redirect_to admin_cruise_line_path(@cruise_line), notice: 'Cruise line was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cruise_line.update(cruise_line_params)
      redirect_to admin_cruise_line_path(@cruise_line), notice: 'Cruise line was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cruise_line.destroy
    redirect_to admin_cruise_lines_path, notice: 'Cruise line was successfully deleted.'
  end

  private

  def set_cruise_line
    @cruise_line = CruiseLine.find(params[:id])
  end

  def cruise_line_params
    params.require(:cruise_line).permit(:name, :name_en, :logo_url, :description, :slug, :data_version)
  end
end
