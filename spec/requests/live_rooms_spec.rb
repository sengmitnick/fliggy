require 'rails_helper'

RSpec.describe "Live rooms", type: :request do
  describe "GET /live_rooms" do
    it "returns http success" do
      get live_rooms_path
      expect(response).to be_success_with_view_check('index')
    end
  end
  
  describe "Follow functionality" do
    let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }
    let(:live_room_name) { "旅游环境01 直播间" }
    
    before do
      # Authenticate user for follow actions
      sign_in_as(user)
    end
    
    describe "POST /live_rooms/:id/follow" do
      it "creates a follow record" do
        expect {
          post follow_live_room_path(live_room_name), headers: { 'Accept' => 'application/json' }
        }.to change { Follow.count }.by(1)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['is_following']).to be true
      end
      
      it "returns error when already following" do
        # Create existing follow
        Follow.create!(
          user: user,
          followable_type: "LiveRoom",
          followable_id: live_room_name
        )
        
        expect {
          post follow_live_room_path(live_room_name), headers: { 'Accept' => 'application/json' }
        }.not_to change { Follow.count }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("已经关注过了")
      end
    end
    
    describe "DELETE /live_rooms/:id/unfollow" do
      it "destroys a follow record" do
        # Create follow first
        Follow.create!(
          user: user,
          followable_type: "LiveRoom",
          followable_id: live_room_name
        )
        
        expect {
          delete unfollow_live_room_path(live_room_name), headers: { 'Accept' => 'application/json' }
        }.to change { Follow.count }.by(-1)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['is_following']).to be false
      end
      
      it "handles unfollowing when not following" do
        expect {
          delete unfollow_live_room_path(live_room_name), headers: { 'Accept' => 'application/json' }
        }.not_to change { Follow.count }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['is_following']).to be false
      end
    end
  end
end
