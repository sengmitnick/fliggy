class FamilyBenefit < ApplicationRecord
  # Validations
  validates :verification_status, inclusion: { in: %w[unverified verified] }
  validates :family_members, numericality: { greater_than_or_equal_to: 0 }
  validates :adult_count, numericality: { greater_than_or_equal_to: 0 }
  validates :child_count, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :verified, -> { where(verification_status: 'verified') }
  scope :unverified, -> { where(verification_status: 'unverified') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_save :sync_family_members_count
  
  private
  
  def sync_family_members_count
    self.family_members = adult_count + child_count
  end
end
