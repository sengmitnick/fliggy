module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :verify_authenticity_token

      def show
        # 检查数据库连接
        ActiveRecord::Base.connection.execute("SELECT 1")
        
        render json: {
          status: "ok",
          timestamp: Time.current.iso8601,
          environment: Rails.env,
          database: "connected"
        }, status: :ok
      rescue => e
        render json: {
          status: "error",
          error: e.message
        }, status: :service_unavailable
      end
    end
  end
end
