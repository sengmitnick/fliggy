require 'rails_helper'

RSpec.describe "Tour groups", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /tour_groups" do
    it "returns http success" do
      get tour_groups_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /tour_groups/:id" do
    let!(:travel_agency) { TravelAgency.create!(name: "测试旅行社", description: "测试描述") }
    let!(:product) do
      TourGroupProduct.create!(
        title: "测试旅游产品",
        destination: "上海",
        price: 299,
        travel_agency: travel_agency,
        tour_category: "group_tour",
        image_url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600"
      )
    end
    let!(:package) do
      TourPackage.create!(
        tour_group_product: product,
        name: "标准套餐",
        price: 299,
        child_price: 199,
        is_featured: true,
        display_order: 1
      )
    end
    let!(:itinerary) do
      TourItineraryDay.create!(
        tour_group_product: product,
        day_number: 1,
        title: "第一天行程",
        attractions: ["景点1", "景点2"],
        duration_minutes: 480
      )
    end
    let!(:user) { User.create!(email: "test@example.com", password: "password") }
    let!(:review) do
      TourReview.create!(
        tour_group_product: product,
        user: user,
        rating: 4.8,
        guide_attitude: 5.0,
        meal_quality: 4.5,
        itinerary_arrangement: 4.8,
        travel_transportation: 4.7,
        comment: "非常棒的旅游体验！"
      )
    end

    it "returns http success" do
      get tour_group_path(product)
      expect(response).to be_success_with_view_check('show')
    end

    it "displays product title" do
      get tour_group_path(product)
      expect(response.body).to include(product.title)
    end

    it "displays package information" do
      get tour_group_path(product)
      expect(response.body).to include("标准套餐")
      expect(response.body).to include("¥299")
    end

    it "displays merchant information" do
      get tour_group_path(product)
      expect(response.body).to include("测试旅行社")
      expect(response.body).to include("商家信息")
    end

    it "displays tab navigation" do
      get tour_group_path(product)
      expect(response.body).to include('商品')
      expect(response.body).to include('套餐')
      expect(response.body).to include('行程')
      expect(response.body).to include('评价')
      expect(response.body).to include('费用')
    end

    it "displays itinerary when requested" do
      get tour_group_path(product, tab: 'itinerary')
      expect(response).to be_successful
      expect(response.body).to include("第一天行程")
      expect(response.body).to include("景点1")
    end

    it "displays reviews when requested" do
      get tour_group_path(product, tab: 'reviews')
      expect(response).to be_successful
      expect(response.body).to include("非常棒的旅游体验")
      expect(response.body).to include("综合评分")
    end

    it "displays bottom action bar" do
      get tour_group_path(product)
      expect(response.body).to include("立即购买")
      expect(response.body).to include("加入购物车")
      expect(response.body).to include("收藏")
    end
  end

end
