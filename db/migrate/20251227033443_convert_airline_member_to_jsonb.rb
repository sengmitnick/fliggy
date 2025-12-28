class ConvertAirlineMemberToJsonb < ActiveRecord::Migration[7.2]
  def up
    # 添加新的 jsonb 字段
    add_column :users, :airline_memberships, :jsonb, default: {}
    
    # 迁移现有数据：如果 airline_member 为 true，则设置所有航空公司为会员
    User.where(airline_member: true).find_each do |user|
      user.update_column(:airline_memberships, {
        '东航' => true,
        '海航' => true,
        '川航' => true,
        '南航' => true,
        '国航' => true
      })
    end
    
    # 删除旧字段
    remove_column :users, :airline_member
  end

  def down
    # 添加回布尔字段
    add_column :users, :airline_member, :boolean, default: false
    
    # 迁移数据回去：如果有任何航空公司会员身份，则设为 true
    User.where("airline_memberships != '{}'").find_each do |user|
      has_membership = user.airline_memberships.values.any? { |v| v == true }
      user.update_column(:airline_member, has_membership)
    end
    
    # 删除 jsonb 字段
    remove_column :users, :airline_memberships
  end
end
