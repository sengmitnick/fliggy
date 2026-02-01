# frozen_string_literal: true

# Stores conversation history for multi-turn dialogue validators
# Each turn represents one message exchange between simul_user and agent
class DialogTurn < ApplicationRecord
  belongs_to :validator_execution, optional: true

  validates :turn_number, presence: true, numericality: { greater_than: 0 }
  validates :role, presence: true, inclusion: { in: %w[simul_user agent] }
  validates :message, presence: true
  validates :data_version, presence: true

  scope :ordered, -> { order(turn_number: :asc) }
  scope :by_role, ->(role) { where(role: role) }
  scope :for_session, ->(data_version) { where(data_version: data_version) }
end
