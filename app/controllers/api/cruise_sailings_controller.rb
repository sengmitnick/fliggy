# frozen_string_literal: true

module Api
  class CruiseSailingsController < Api::BaseController
    skip_before_action :verify_authenticity_token, only: [:show]

    def show
      @sailing = CruiseSailing.includes(:cruise_ship, :cruise_route).find(params[:id])
      
      render json: {
        id: @sailing.id,
        departure_date: @sailing.departure_date,
        return_date: @sailing.return_date,
        duration_days: @sailing.duration_days,
        duration_nights: @sailing.duration_nights,
        departure_port: @sailing.departure_port,
        arrival_port: @sailing.arrival_port,
        boarding_address: @sailing.boarding_address,
        boarding_deadline: @sailing.boarding_deadline,
        itinerary: @sailing.itinerary || [],
        cruise_ship: {
          name: @sailing.cruise_ship.name,
          name_en: @sailing.cruise_ship.name_en
        },
        cruise_route: {
          name: @sailing.cruise_route.name
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Sailing not found' }, status: :not_found
    end
  end
end
