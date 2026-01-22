require 'rails_helper'

RSpec.describe "Tickets", type: :request do
  let(:city) { '深圳' }
  let!(:travel_agency) { create(:travel_agency, name: '深圳旅游专营店') }
  
  describe "GET /tickets" do
    context "when no tickets exist" do
      it "returns success with empty results" do
        get tickets_path
        expect(response).to have_http_status(:success)
      end
    end
    
    context "when tickets exist" do
      let!(:ticket_product) do
        create(:tour_group_product,
          tour_category: 'ticket',
          destination: city,
          title: '深圳平安金融中心云际观光层',
          rating: 4.6,
          rating_desc: '500+点评',
          price: 174.8,
          sales_count: 2000,
          tags: ['360度云端纵览', '赏绝美夜景'],
          travel_agency: travel_agency
        )
      end
      
      it "returns success and displays tickets" do
        get tickets_path(city: city)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('深圳平安金融中心云际观光层')
      end
      
      it "filters by city" do
        create(:tour_group_product, tour_category: 'ticket', destination: '上海', travel_agency: travel_agency)
        get tickets_path(city: city)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(city)
      end
      
      it "sorts by sales when sort_by=sales" do
        get tickets_path(city: city, sort_by: 'sales')
        expect(response).to have_http_status(:success)
      end
      
      it "filters by tag" do
        get tickets_path(city: city, tag: '360度云端纵览')
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe "GET /tickets/:id" do
    let!(:ticket_product) do
      create(:tour_group_product,
        tour_category: 'ticket',
        destination: city,
        travel_agency: travel_agency
      )
    end
    
    it "redirects to tour_group show page" do
      get ticket_path(ticket_product)
      expect(response).to redirect_to(tour_group_path(ticket_product))
    end
  end
end
