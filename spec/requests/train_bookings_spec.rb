require 'rails_helper'

RSpec.describe "Train bookings", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /train_bookings/:id" do
    let(:train_booking_record) { create(:train_booking, user: user) }


    it "returns http success" do
      get train_booking_path(train_booking_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /train_bookings/new" do
    let(:train) { create(:train) }
    
    it "renders the booking form page" do
      get new_train_booking_path(train_id: train.id)
      expect(response).to be_success_with_view_check('new')
    end
    
    it "accepts seat_type parameter" do
      get new_train_booking_path(train_id: train.id, seat_type: 'first_class')
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
