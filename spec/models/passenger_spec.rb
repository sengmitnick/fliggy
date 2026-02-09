# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Passenger, type: :model do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  describe '#age' do
    context '当身份证号有效时' do
      it '正确计算成人年龄（1990年出生，36岁）' do
        passenger = user.passengers.create!(
          name: '张三',
          id_type: '身份证',
          id_number: '110101199001011234',
          phone: '13800138000'
        )
        
        expect(passenger.age).to be_between(34, 36)
      end

      it '正确计算儿童年龄（2015年出生，9岁）' do
        passenger = user.passengers.create!(
          name: '小明',
          id_type: '身份证',
          id_number: '110101201507085678',
          phone: '13500135001'
        )
        
        expect(passenger.age).to be_between(8, 10)
      end

      it '正确计算儿童年龄（2018年出生，6岁）' do
        passenger = user.passengers.create!(
          name: '小红',
          id_type: '身份证',
          id_number: '110101201808126789',
          phone: '13400134001'
        )
        
        expect(passenger.age).to be_between(5, 7)
      end
    end

    context '当身份证号无效时' do
      it '返回 nil' do
        passenger = user.passengers.new(
          name: '测试',
          id_type: '身份证',
          id_number: '000000000000000000'
        )
        
        expect(passenger.age).to be_nil
      end
    end

    context '当证件类型不是身份证时' do
      it '返回 nil' do
        passenger = user.passengers.new(
          name: '测试',
          id_type: '护照',
          id_number: 'E12345678'
        )
        
        expect(passenger.age).to be_nil
      end
    end
  end

  describe '#child_ticket?' do
    it '12岁以下返回 true' do
      passenger = user.passengers.create!(
        name: '小明',
        id_type: '身份证',
        id_number: '110101201507085678',
        phone: '13500135001'
      )
      
      expect(passenger.child_ticket?).to be true
    end

    it '12岁及以上返回 false' do
      passenger = user.passengers.create!(
        name: '张三',
        id_type: '身份证',
        id_number: '110101199001011234',
        phone: '13800138000'
      )
      
      expect(passenger.child_ticket?).to be false
    end
  end

  describe '#ticket_type_label' do
    it '儿童返回"儿童票"' do
      passenger = user.passengers.create!(
        name: '小明',
        id_type: '身份证',
        id_number: '110101201507085678',
        phone: '13500135001'
      )
      
      expect(passenger.ticket_type_label).to eq('儿童票')
    end

    it '成人返回"成人票"' do
      passenger = user.passengers.create!(
        name: '张三',
        id_type: '身份证',
        id_number: '110101199001011234',
        phone: '13800138000'
      )
      
      expect(passenger.ticket_type_label).to eq('成人票')
    end
  end
end
