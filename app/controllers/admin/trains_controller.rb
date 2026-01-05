class Admin::TrainsController < Admin::BaseController
  before_action :set_train, only: [:show, :edit, :update, :destroy]

  def index
    @trains = Train.page(params[:page]).per(10).order(departure_time: :desc)
  end

  def show
  end

  def new
    @train = Train.new
  end

  def create
    @train = Train.new(train_params)

    if @train.save
      redirect_to admin_train_path(@train), notice: 'Train was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @train.update(train_params)
      redirect_to admin_train_path(@train), notice: 'Train was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @train.destroy
    redirect_to admin_trains_path, notice: 'Train was successfully deleted.'
  end

  # Batch generator page
  def generator
    @cities = City.pluck(:name).sort
  end

  # Batch generate trains
  def batch_generate
    departure_city = params[:departure_city]
    arrival_city = params[:arrival_city]
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    if departure_city.blank? || arrival_city.blank?
      redirect_to generator_admin_trains_path, alert: '请选择出发城市和到达城市'
      return
    end

    if start_date > end_date
      redirect_to generator_admin_trains_path, alert: '开始日期不能晚于结束日期'
      return
    end

    total_trains = 0
    (start_date..end_date).each do |date|
      trains = Train.generate_for_route(departure_city, arrival_city, date)
      total_trains += trains.count
    end

    redirect_to admin_trains_path, notice: "成功生成 #{total_trains} 个车次 (#{departure_city} → #{arrival_city}, #{start_date} 至 #{end_date})"
  rescue ArgumentError => e
    redirect_to generator_admin_trains_path, alert: "日期格式错误: #{e.message}"
  end

  private

  def set_train
    @train = Train.find(params[:id])
  end

  def train_params
    params.require(:train).permit(:departure_city, :arrival_city, :train_number, :departure_time, :arrival_time, :duration, :price_second_class, :price_first_class, :price_business_class, :available_seats)
  end
end
