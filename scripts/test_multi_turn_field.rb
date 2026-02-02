#!/usr/bin/env ruby
# frozen_string_literal: true

# 验证 is_multi_turn 字段实现
#
# 使用方法：
# rails runner scripts/test_multi_turn_field.rb

require 'rails'

puts "=" * 80
puts "测试 is_multi_turn 字段实现"
puts "=" * 80
puts ""

# 测试 BaseValidator
puts "1. 测试 BaseValidator (应该返回 is_multi_turn: false)"
puts "-" * 40

class TestBaseValidator < BaseValidator
  self.validator_id = 'test_base'
  self.task_id = SecureRandom.uuid
  self.title = '测试基础验证器'
  self.description = '测试 is_multi_turn 字段'
  
  def prepare
    {}
  end
  
  def verify
  end
  
  def simulate
  end
end

metadata = TestBaseValidator.metadata
puts "metadata = #{metadata.inspect}"
puts "is_multi_turn = #{metadata[:is_multi_turn]}"
puts ""

if metadata[:is_multi_turn] == false
  puts "✅ PASS: BaseValidator 正确返回 is_multi_turn: false"
else
  puts "❌ FAIL: BaseValidator 应该返回 is_multi_turn: false，实际返回 #{metadata[:is_multi_turn]}"
end

puts ""

# 测试 MultiTurnBaseValidator
puts "2. 测试 MultiTurnBaseValidator (应该返回 is_multi_turn: true)"
puts "-" * 40

class TestMultiTurnValidator < MultiTurnBaseValidator
  self.validator_id = 'test_multi_turn'
  self.task_id = SecureRandom.uuid
  self.title = '测试多轮对话验证器'
  self.description = '测试 is_multi_turn 字段'
  
  def prepare
    {}
  end
  
  def initial_task_goal
    "测试任务"
  end
  
  def verify
  end
  
  def simulate
  end
end

metadata = TestMultiTurnValidator.metadata
puts "metadata = #{metadata.inspect}"
puts "is_multi_turn = #{metadata[:is_multi_turn]}"
puts ""

if metadata[:is_multi_turn] == true
  puts "✅ PASS: MultiTurnBaseValidator 正确返回 is_multi_turn: true"
else
  puts "❌ FAIL: MultiTurnBaseValidator 应该返回 is_multi_turn: true，实际返回 #{metadata[:is_multi_turn]}"
end

puts ""
puts "=" * 80
puts "测试完成"
puts "=" * 80
