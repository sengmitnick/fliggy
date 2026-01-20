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

  # Format predicted contact deadline
  def format_predicted_contact_deadline(request)
    contact_time = request.contact_time
    created_at = request.created_at
    
    deadline = case contact_time
    when '尽快联系 | 提交后30分钟内'
      created_at + 30.minutes
    when '上午8点-12点'
      # Next day at 12:00
      (created_at + 1.day).change(hour: 12, min: 0)
    when '下午12点-18点'
      # Next day at 18:00
      (created_at + 1.day).change(hour: 18, min: 0)
    when '晚上18点-21点'
      # Next day at 21:00
      (created_at + 1.day).change(hour: 21, min: 0)
    when '任意时间'
      # Next day at 23:59
      (created_at + 1.day).change(hour: 23, min: 59)
    else
      # Default to next day 16:23
      (created_at + 1.day).change(hour: 16, min: 23)
    end
    
    "#{deadline.strftime('%m月%d日')} (#{format_weekday(deadline)}) #{deadline.strftime('%H:%M')}前"
  end

  private

  # Get Chinese weekday name
  def format_weekday(date)
    weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    weekdays[date.wday]
  end

  # Generate communication timeline events
  def generate_timeline_events(request)
    events = []
    
    # Event 1: Order created
    events << {
      type: 'created',
      title: '提交定制需求',
      description: '你已提交定制旅行需求，等待商家接单',
      time: request.created_at,
      icon: 'check',
      color: 'blue'
    }
    
    # Event 2: Order cancelled (if applicable)
    if request.cancelled?
      events << {
        type: 'cancelled',
        title: '订单已取消',
        description: '你已取消此定制旅行订单',
        time: request.updated_at,
        icon: 'close',
        color: 'gray'
      }
    end
    
    events
  end

  # Format timeline event time
  def format_timeline_time(time)
    "#{time.strftime('%m月%d日')} #{time.strftime('%H:%M')}"
  end
end
