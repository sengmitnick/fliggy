require 'rails_helper'

RSpec.describe CarOrder, type: :model do
  describe '#rental_days' do
    let(:car) { create(:car) }
    let(:user) { create(:user) }
    
    context 'when pickup_datetime and return_datetime are present' do
      it 'calculates rental days correctly for same day (11 hours)' do
        # 同一天租车：9:00 到 20:00 (11小时)
        car_order = CarOrder.create!(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区',
          pickup_datetime: Time.zone.parse('2026-03-10 09:00'),
          return_datetime: Time.zone.parse('2026-03-10 20:00'),
          driver_name: '张三',
          driver_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: 300
        )
        
        expect(car_order.rental_days).to eq(1)
      end
      
      it 'calculates rental days correctly for 24+ hours' do
        # 24小时+1分钟 = 2天
        car_order = CarOrder.create!(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区',
          pickup_datetime: Time.zone.parse('2026-03-10 09:00'),
          return_datetime: Time.zone.parse('2026-03-11 09:01'),
          driver_name: '张三',
          driver_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: 600
        )
        
        expect(car_order.rental_days).to eq(2)
      end
      
      it 'calculates rental days correctly for multiple days' do
        # 3天租期：27号上午9点 -> 30号上午9点 (恰好72小时=3天)
        car_order = CarOrder.create!(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区',
          pickup_datetime: Time.zone.parse('2026-03-27 09:00'),
          return_datetime: Time.zone.parse('2026-03-30 09:00'),
          driver_name: '张三',
          driver_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: 900
        )
        
        expect(car_order.rental_days).to eq(3)
      end
      
      it 'rounds up partial days' do
        # 1天+1小时 = 2天 (向上取整)
        car_order = CarOrder.create!(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区',
          pickup_datetime: Time.zone.parse('2026-03-10 09:00'),
          return_datetime: Time.zone.parse('2026-03-11 10:00'),
          driver_name: '张三',
          driver_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: 600
        )
        
        expect(car_order.rental_days).to eq(2)
      end
    end
    
    context 'when datetime fields are missing' do
      it 'returns nil when pickup_datetime is missing' do
        car_order = CarOrder.new(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区',
          return_datetime: Time.zone.parse('2026-03-10 20:00')
        )
        
        expect(car_order.rental_days).to be_nil
      end
      
      it 'returns nil when return_datetime is missing' do
        car_order = CarOrder.new(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区',
          pickup_datetime: Time.zone.parse('2026-03-10 09:00')
        )
        
        expect(car_order.rental_days).to be_nil
      end
      
      it 'returns nil when both datetime fields are missing' do
        car_order = CarOrder.new(
          car: car,
          user: user,
          pickup_location: '北京市朝阳区'
        )
        
        expect(car_order.rental_days).to be_nil
      end
    end
  end
end
