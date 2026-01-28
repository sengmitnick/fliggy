require 'rails_helper'

RSpec.describe "Membership products", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /membership_products" do
    it "returns http success" do
      get membership_products_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /membership_products/:id" do
    let(:membership_product_record) { create(:membership_product) }


    it "returns http success" do
      get membership_product_path(membership_product_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
