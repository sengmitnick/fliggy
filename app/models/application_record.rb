class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # 全局启用 DataVersionable 功能（中间件模式）
  # 所有继承 ApplicationRecord 的模型自动获得：
  # 1. 创建时自动设置 data_version（before_create 钩子）
  # 2. 查询时自动过滤 data_version（default_scope）
  include DataVersionable

  # Helper: Generate full URL for ActiveStorage attachments
  def attachment_url(attachment)
    return nil unless attachment.attached?
    Rails.application.routes.url_helpers.rails_blob_url(attachment)
  end
end
