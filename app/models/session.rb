class Session < ApplicationRecord
  belongs_to :user

  # Session 是系统模型，不使用 data_version 机制
  # 需要移除 ApplicationRecord 继承的 default_scope 和 callbacks
  default_scope { unscope(where: :data_version) }
  skip_callback :create, :before, :set_data_version

  before_create do
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end
end
