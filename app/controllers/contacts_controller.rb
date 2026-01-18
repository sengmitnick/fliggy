class ContactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact, only: [:edit, :update, :destroy]

  def index
    @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc)
  end

  def new
    @contact = current_user.contacts.build
  end

  def create
    @contact = current_user.contacts.build(contact_params)
    
    if @contact.save
      redirect_to contacts_path, notice: "联系人添加成功"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: "联系人更新成功"
    else
      render :edit
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path, notice: "联系人删除成功"
  end

  private

  def set_contact
    @contact = current_user.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :phone, :email, :is_default)
  end

  def authenticate_user!
    unless current_user
      redirect_to sign_in_path, alert: '请先登录'
    end
  end
end
