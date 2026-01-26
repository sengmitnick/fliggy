require 'rails_helper'

RSpec.describe "Admin::Sessions Redirect", type: :request do
  let(:admin) { create(:administrator) }

  describe "POST /admin/login" do
    context "when return_to path is stored in session" do
      it "redirects to the stored path after successful login" do
        # Simulate accessing a protected page which stores the return_to path
        get admin_validation_tasks_path
        expect(response).to redirect_to(admin_login_path)
        
        # Session should store the return_to path
        expect(session[:admin_return_to]).to eq(admin_validation_tasks_path)
        
        # Login with correct credentials
        post admin_login_path, params: { name: admin.name, password: 'admin' }
        
        # Should redirect to the stored path, not admin root
        expect(response).to redirect_to(admin_validation_tasks_path)
        
        # Session should clear the return_to path
        expect(session[:admin_return_to]).to be_nil
      end

      it "redirects to specific validation task page after login" do
        target_path = '/admin/validation_tasks/v006_book_morning_bus_validator'
        
        # Simulate accessing the specific validation task page
        get target_path
        expect(response).to redirect_to(admin_login_path)
        expect(session[:admin_return_to]).to eq(target_path)
        
        # Login with correct credentials
        post admin_login_path, params: { name: admin.name, password: 'admin' }
        
        # Should redirect back to the validation task page
        expect(response).to redirect_to(target_path)
        expect(session[:admin_return_to]).to be_nil
      end
    end

    context "when no return_to path is stored" do
      it "redirects to admin root path after successful login" do
        post admin_login_path, params: { name: admin.name, password: 'admin' }
        
        expect(response).to redirect_to(admin_root_path)
      end
    end

    context "when password is changed" do
      before { admin_sign_in_as(admin) }

      it "stores return_to path when password digest mismatch" do
        # Manually change the admin's password (simulating password change from another session)
        admin.update!(password: 'newpassword', password_confirmation: 'newpassword')
        
        # Try to access a protected page with old session token
        get admin_validation_tasks_path
        
        # Should redirect to login and store the path
        expect(response).to redirect_to(admin_login_path)
        expect(session[:admin_return_to]).to eq(admin_validation_tasks_path)
      end
    end

    context "when request is XHR" do
      it "does not store return_to path for AJAX requests" do
        get admin_validation_tasks_path, xhr: true
        
        expect(response).to redirect_to(admin_login_path)
        expect(session[:admin_return_to]).to be_nil
      end
    end
  end
end
