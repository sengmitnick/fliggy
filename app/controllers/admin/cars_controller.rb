class Admin::CarsController < Admin::BaseController
  before_action :set_car, only: [:show, :edit, :update, :destroy]

  def index
    @cars = Car.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @car = Car.new
  end

  def create
    @car = Car.new(car_params)

    if @car.save
      redirect_to admin_car_path(@car), notice: 'Car was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @car.update(car_params)
      redirect_to admin_car_path(@car), notice: 'Car was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @car.destroy
    redirect_to admin_cars_path, notice: 'Car was successfully deleted.'
  end

  # Batch generator page
  def generator
    @cities = City.pluck(:name).sort
  end

  # Batch generate cars using seeds data
  def batch_generate
    location = params[:location]

    if location.blank?
      redirect_to generator_admin_cars_path, alert: '请选择城市'
      return
    end

    # Load cars data from seeds
    cars_data = [
      {
        brand: "特斯拉",
        car_model: "Model 3",
        category: "舒适轿车",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "纯电动",
        engine: "电动",
        price_per_day: 72,
        total_price: 324,
        discount_amount: 72,
        features: "舒适轿车 | 5座4门 | 自动挡 | 纯电动",
        tags: "销量第一,机车特惠,VR看车",
        image_url: "https://images.unsplash.com/photo-1560958089-b8a1929cea89",
        is_featured: true,
        is_available: true,
        sales_rank: 1
      },
      {
        brand: "别克",
        car_model: "凯越",
        category: "经济轿车",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "1.3L",
        price_per_day: 11,
        total_price: 42,
        discount_amount: 50,
        features: "经济轿车 | 5座4门 | 自动挡 | 1.3L",
        tags: "总价最低,机车特惠",
        image_url: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf",
        is_featured: true,
        is_available: true,
        sales_rank: 2
      },
      {
        brand: "丰田",
        car_model: "锋兰达",
        category: "SUV",
        seats: 5,
        doors: 5,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "2.0L",
        price_per_day: 29,
        total_price: 78,
        discount_amount: 50,
        features: "SUV | 5座5门 | 自动挡 | 2.0L",
        tags: "机车特惠,VR看车",
        image_url: "https://images.unsplash.com/photo-1519641471654-76ce0107ad1b",
        is_featured: false,
        is_available: true,
        sales_rank: 3
      },
      {
        brand: "本田",
        car_model: "飞度",
        category: "经济轿车",
        seats: 5,
        doors: 5,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "1.5L",
        price_per_day: 26,
        total_price: 104,
        discount_amount: 30,
        features: "经济轿车 | 5座5门 | 自动挡 | 1.5L",
        tags: "低价好车,城市热销",
        image_url: "https://images.unsplash.com/photo-1552519507-da3b142c6e3d",
        is_featured: true,
        is_available: true,
        sales_rank: 4
      },
      {
        brand: "大众",
        car_model: "朗逸",
        category: "经济轿车",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "1.5L",
        price_per_day: 36,
        total_price: 144,
        discount_amount: 40,
        features: "经济轿车 | 5座4门 | 自动挡 | 1.5L",
        tags: "城市热销",
        image_url: "https://images.unsplash.com/photo-1580273916550-e323be2ae537",
        is_featured: true,
        is_available: true,
        sales_rank: 5
      },
      {
        brand: "丰田",
        car_model: "RAV4荣放",
        category: "SUV",
        seats: 5,
        doors: 5,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "2.0L",
        price_per_day: 34,
        total_price: 136,
        discount_amount: 35,
        features: "SUV | 5座5门 | 自动挡 | 2.0L",
        tags: "",
        image_url: "https://images.unsplash.com/photo-1617469767053-d3b523a0b982",
        is_featured: false,
        is_available: true,
        sales_rank: 6
      },
      {
        brand: "雪佛兰",
        car_model: "科鲁兹",
        category: "经济轿车",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "1.5L",
        price_per_day: 34,
        total_price: 136,
        discount_amount: 35,
        features: "经济轿车 | 5座4门 | 自动挡 | 1.5L",
        tags: "",
        image_url: "https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2",
        is_featured: false,
        is_available: true,
        sales_rank: 7
      },
      {
        brand: "比亚迪",
        car_model: "秦PLUS DM-i",
        category: "新能源",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "插电混动",
        engine: "混合动力",
        price_per_day: 35,
        total_price: 140,
        discount_amount: 40,
        features: "新能源 | 5座4门 | 自动挡 | 插电混动",
        tags: "新能源车,环保节能",
        image_url: "https://images.unsplash.com/photo-1593941707882-a5bba14938c7",
        is_featured: false,
        is_available: true,
        sales_rank: 8
      },
      {
        brand: "五菱",
        car_model: "宏光MINIEV",
        category: "新能源",
        seats: 4,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "纯电动",
        engine: "电动",
        price_per_day: 18,
        total_price: 72,
        discount_amount: 25,
        features: "新能源 | 4座4门 | 自动挡 | 纯电动",
        tags: "新能源车,小巧灵活",
        image_url: "https://images.unsplash.com/photo-1609521263047-f8f205293f24",
        is_featured: false,
        is_available: true,
        sales_rank: 9
      },
      {
        brand: "本田",
        car_model: "雅阁",
        category: "舒适轿车",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "1.5T",
        price_per_day: 58,
        total_price: 232,
        discount_amount: 60,
        features: "舒适轿车 | 5座4门 | 自动挡 | 1.5T",
        tags: "商务首选",
        image_url: "https://images.unsplash.com/photo-1590362891991-f776e747a588",
        is_featured: false,
        is_available: true,
        sales_rank: 10
      },
      {
        brand: "别克",
        car_model: "GL8",
        category: "商务车",
        seats: 7,
        doors: 5,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "2.0T",
        price_per_day: 150,
        total_price: 600,
        discount_amount: 80,
        features: "商务车 | 7座5门 | 自动挡 | 2.0T",
        tags: "商务接待,宽敞舒适",
        image_url: "https://images.unsplash.com/photo-1464219789935-c2d9d9aba644",
        is_featured: false,
        is_available: true,
        sales_rank: 11
      },
      {
        brand: "奔驰",
        car_model: "E级",
        category: "豪华轿车",
        seats: 5,
        doors: 4,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "2.0T",
        price_per_day: 380,
        total_price: 1520,
        discount_amount: 100,
        features: "豪华轿车 | 5座4门 | 自动挡 | 2.0T",
        tags: "豪华商务,尊贵体验",
        image_url: "https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8",
        is_featured: false,
        is_available: true,
        sales_rank: 12
      },
      {
        brand: "保时捷",
        car_model: "718",
        category: "跑车",
        seats: 2,
        doors: 2,
        transmission: "自动挡",
        fuel_type: "汽油",
        engine: "2.0T",
        price_per_day: 900,
        total_price: 3600,
        discount_amount: 200,
        features: "跑车 | 2座2门 | 自动挡 | 2.0T",
        tags: "超跑体验,激情驾驶",
        image_url: "https://images.unsplash.com/photo-1503376780353-7e6692767b70",
        is_featured: false,
        is_available: true,
        sales_rank: 13
      }
    ]

    total_cars = 0
    cars_data.each do |car_data|
      car_data[:location] = location
      car_data[:pickup_location] = "#{location}天河国际机场T3"
      Car.create!(car_data)
      total_cars += 1
    end

    redirect_to admin_cars_path, notice: "成功生成 #{total_cars} 辆车 (#{location})"
  end

  private

  def set_car
    @car = Car.find(params[:id])
  end

  def car_params
    params.require(:car).permit(:brand, :car_model, :category, :seats, :doors, :transmission, :fuel_type, :engine, :price_per_day, :total_price, :discount_amount, :location, :pickup_location, :features, :tags, :is_featured, :is_available, :sales_rank, :image_url)
  end
end
