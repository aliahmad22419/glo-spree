module UserSessionsControllerDecorator

  def self.prepended(base)
    base.before_action :authorize_store_client, only: [:create]
  end

  def authorize_store_client
    # @user = Spree::User.find_by_email params[:spree_user][:email]
    # unless @user&.spree_roles&.map(&:name)&.include?("admin")
    #   unless current_store.client == @user.try(:client)
    #     sign_out(spree_current_user)
    #     flash[:error] = 'You are not authorized'
    #     redirect_to login_path and return
    #   end
    # end
  end

  def create
    super
  end
end

::Spree::UserSessionsController.prepend UserSessionsControllerDecorator
