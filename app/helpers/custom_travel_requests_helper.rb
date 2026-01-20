module CustomTravelRequestsHelper
  # Format contact time display
  def format_contact_time(request)
    if request.contact_time.present?
      request.contact_time
    else
      contact_date = Time.current + 1.day
      "#{contact_date.strftime('%m月%d日')} (#{format_weekday(contact_date)}) 16:23前"
    end
  end

  # Format departure date
  def format_departure_date(request)
    if request.departure_date.present?
      date = request.departure_date
      "#{date.strftime('%m月%d日')} (#{format_weekday(date)})"
    else
      '无明确日期'
    end
  end

  # Format people count
  def format_people_count(request)
    parts = []
    parts << "#{request.adults_count}成人" if request.adults_count > 0
    parts << "#{request.children_count}儿童" if request.children_count > 0
    parts << "#{request.elders_count}老人" if request.elders_count > 0
    parts.any? ? parts.join(' ') : '2成人'
  end

  # Format budget (placeholder since not in model)
  def format_budget(request)
    # Parse from preferences if available, otherwise return default
    if request.preferences.present? && request.preferences.match?(/\d+/)
      "#{request.preferences.scan(/\d+/).first}元/人"
    else
      '无明确预算'
    end
  end

  # Format order number
  def format_order_number(request)
    # Generate order number from ID (7 digits)
    request.id.to_s.rjust(7, '0')
  end

  # Format submit time
  def format_submit_time(request)
    request.created_at.strftime('%Y-%m-%d %H:%M:%S')
  end

  private

  # Get Chinese weekday name
  def format_weekday(date)
    weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    weekdays[date.wday]
  end
end
