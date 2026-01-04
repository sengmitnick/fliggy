# Booking flow service handles the standard booking workflow:
# 1. Fill form
# 2. Select insurance (optional)
# 3. Lock resource (room/seat)
# 4. Confirm and pay
class BookingFlowService < ApplicationService
  attr_reader :booking, :errors

  def initialize(booking)
    @booking = booking
    @errors = []
  end

  # Lock the resource associated with the booking
  def lock_resource
    case booking.class.name
    when 'HotelBooking'
      lock_hotel_room
    when 'Booking'  # Flight booking
      # Flights don't need explicit locking (seats are decremented on save)
      true
    else
      @errors << "Unknown booking type"
      false
    end
  end

  # Process insurance selection
  def process_insurance(insurance_type, trip_type: :single, trip_count: 1)
    calculated_price = InsuranceService.calculate_price(
      insurance_type,
      booking_type: trip_type,
      trip_count: trip_count
    )

    booking.insurance_type = insurance_type.to_s
    booking.insurance_price = calculated_price
    true
  end

  # Complete payment and finalize booking
  def complete_payment
    return false unless booking.valid?

    booking.status = 'paid'
    
    # Release lock since payment is completed
    release_lock if booking.respond_to?(:locked_until)
    
    if booking.save
      create_success_notification
      true
    else
      @errors << booking.errors.full_messages
      false
    end
  end

  # Cancel booking and release lock
  def cancel_booking
    booking.status = 'cancelled'
    release_lock if booking.respond_to?(:locked_until)
    booking.save
  end

  private

  # Lock hotel room for 10 minutes
  def lock_hotel_room
    return false unless booking.respond_to?(:hotel_room)
    return false if booking.hotel_room.nil?

    # Set lock expiry to 10 minutes from now
    booking.locked_until = 10.minutes.from_now
    
    # Save to persist the lock
    if booking.save(validate: false)
      true
    else
      @errors << "Failed to lock hotel room"
      false
    end
  end

  # Release resource lock
  def release_lock
    case booking.class.name
    when 'HotelBooking'
      booking.locked_until = nil
      booking.save(validate: false)
    end
  end

  # Create success notification after booking
  def create_success_notification
    return unless booking.respond_to?(:user) && booking.user.present?

    case booking.class.name
    when 'HotelBooking'
      create_hotel_notification
    when 'Booking'
      # Flight notifications are handled in the Booking model
      booking.create_booking_notification if booking.respond_to?(:create_booking_notification)
    end
  end

  def create_hotel_notification
    hotel = booking.hotel
    booking.user.notifications.create!(
      category: 'itinerary',
      title: '订单行程消息提醒',
      content: "预定成功，请于#{booking.check_in_date.strftime('%m月%d日')}办理入住#{hotel.name}",
      read: false
    )
  end

  # Check if resource lock has expired
  def self.lock_expired?(booking)
    return false unless booking.respond_to?(:locked_until)
    return false if booking.locked_until.nil?
    
    booking.locked_until < Time.current
  end
end
