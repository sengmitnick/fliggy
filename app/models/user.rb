class User < ApplicationRecord
  has_many :user_coupons, dependent: :destroy
  has_many :abroad_coupons, through: :user_coupons

  MIN_PASSWORD = 4
  GENERATED_EMAIL_SUFFIX = "@generated-mail.clacky.ai"

  has_secure_password validations: false
  has_secure_password :pay_password, validations: false

  # ========== Role-based Access Control (Optional) ==========
  # If you need roles (premium, moderator, etc.), add a `role` field:
  #   rails g migration AddRoleToUsers role:string
  #   # In migration: add_column :users, :role, :string, default: 'user', null: false
  #   # Then add in this model:
  #   ROLES = %w[user premium moderator].freeze
  #   validates :role, inclusion: { in: ROLES }
  #   def premium? = role == 'premium'
  #   def moderator? = role == 'moderator'
  # ==========================================================

  # ========== Multi-Role Separate Routes (e.g. Doctor/Patient) ==========
  # For apps needing separate signup/login pages per role:
  #   1. ROLES = %w[doctor patient].freeze
  #   2. Add scoped routes: scope '/doctor', as: 'doctor' do ... end
  #   3. In RegistrationsController#create: @user.role = params[:role]
  #   4. Create role-specific views: sessions/new_doctor.html.erb
  #   5. For extra fields per role, use polymorphic Profile:
  #      has_one :doctor_profile, dependent: :destroy
  #      has_one :patient_profile, dependent: :destroy
  #      def profile = doctor? ? doctor_profile : patient_profile
  # See generator output for full setup instructions.
  # ======================================================================

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end
  generates_token_for :password_reset, expires_in: 20.minutes

  has_many :sessions, dependent: :destroy
  has_many :passengers, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :hotel_bookings, dependent: :destroy
  has_many :hotel_package_orders, dependent: :destroy
  has_many :train_bookings, dependent: :destroy
  has_many :tour_group_bookings, dependent: :destroy
  has_many :deep_travel_bookings, dependent: :destroy
  has_many :car_orders, dependent: :destroy
  has_many :bus_ticket_orders, dependent: :destroy
  has_many :internet_orders, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :membership, dependent: :destroy
  has_many :brand_memberships, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :itineraries, dependent: :destroy
  
  after_create :create_default_membership

  # airline_memberships is a jsonb field: { "东航" => true, "海航" => false, ... }
  # Check if user is member of specific airline(s)
  def is_airline_member?(airline_name)
    return false if airline_memberships.blank?
    airline_memberships[airline_name] == true
  end

  # Check if user is member of all specified airlines
  def is_member_of_all?(airline_names)
    airline_names.all? { |name| is_airline_member?(name) }
  end

  # Get list of airlines user is NOT a member of
  def missing_memberships(airline_names)
    airline_names.reject { |name| is_airline_member?(name) }
  end

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, allow_nil: true, length: { minimum: MIN_PASSWORD }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  # OAuth methods
  def self.from_omniauth(auth)
    name = auth.info.name.presence || "#{SecureRandom.hex(10)}_user"
    email = auth.info.email.presence || User.generate_email(name)

    # First, try to find user by email
    user = find_by(email: email)
    if user
      user.update(provider: auth.provider, uid: auth.uid)
      return user
    end

    # Then, try to find user by provider and uid
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # If not found, create a new user
    verified = !email.end_with?(GENERATED_EMAIL_SUFFIX)
    create(
      name: name,
      email: email,
      provider: auth.provider,
      uid: auth.uid,
      verified: verified,
    )
  end

  def self.generate_email(name)
    if name.present?
      name.downcase.gsub(' ', '_') + GENERATED_EMAIL_SUFFIX
    else
      SecureRandom.hex(10) + GENERATED_EMAIL_SUFFIX
    end
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def email_was_generated?
    email.end_with?(GENERATED_EMAIL_SUFFIX)
  end
  
  # 获取未读消息数
  def unread_notifications_count
    notifications.where(read: false).count
  end

  # Check if user has set pay password
  def has_pay_password?
    pay_password_digest.present?
  end

  # Authenticate pay password
  def authenticate_pay_password(password)
    return false unless has_pay_password?
    BCrypt::Password.new(pay_password_digest).is_password?(password)
  end

  private

  def password_required?
    return false if oauth_user?
    password_digest.blank? || password.present?
  end
  
  def create_default_membership
    create_membership!(level: 'F1', points: 0, experience: 0) unless membership
  end

end
