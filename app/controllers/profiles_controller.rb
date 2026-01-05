class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @full_render = true
    @user = current_user
    # 统计信息
    @bookings_count = {
      pending: @user.bookings.pending.count,
      paid: @user.bookings.paid.count,
      completed: @user.bookings.completed.count,
      cancelled: @user.bookings.cancelled.count
    }
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      need_email_verification = @user.previous_changes.include?(:email)
      if need_email_verification
        send_email_verification
        additional_notice = "and sent a verification email to your new email address"
      end
      redirect_to profile_path, notice: "Profile updated #{additional_notice}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit_password
    @user = current_user
  end

  def update_password
    @user = current_user

    unless @user.authenticate(params[:user][:current_password])
      flash.now[:alert] = "Password not correct"
      render :edit_password, status: :unprocessable_entity
      return
    end

    if @user.update(password_params)
      redirect_to profile_path, notice: "Password updated"
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  def edit_pay_password
    @user = current_user
  end

  def update_pay_password
    @user = current_user

    # If user already has a pay password, verify current pay password
    if @user.has_pay_password?
      unless @user.authenticate_pay_password(params[:user][:current_pay_password])
        flash.now[:alert] = "当前支付密码不正确"
        render :edit_pay_password, status: :unprocessable_entity
        return
      end
    end

    if @user.update(pay_password_params)
      redirect_to profile_path, notice: "支付密码设置成功"
    else
      render :edit_pay_password, status: :unprocessable_entity
    end
  end

  def verify_pay_password
    unless current_user.has_pay_password?
      render json: { success: false, message: '请先设置支付密码' }, status: :unprocessable_entity
      return
    end

    pay_password = params[:pay_password]
    if current_user.authenticate_pay_password(pay_password)
      render json: { success: true }
    else
      render json: { success: false, message: '支付密码错误' }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def pay_password_params
    params.require(:user).permit(:pay_password, :pay_password_confirmation)
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
