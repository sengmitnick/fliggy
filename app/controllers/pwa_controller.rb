class PwaController < ApplicationController
  # Skip browser version check for PWA files
  skip_before_action :verify_authenticity_token
  
  def manifest
    render 'pwa/manifest', layout: false, formats: [:json], content_type: 'application/manifest+json'
  end

  def service_worker
    expires_in 0.seconds, public: true
    render 'pwa/service_worker', layout: false, content_type: 'application/javascript'
  end
end
