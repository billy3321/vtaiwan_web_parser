class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]
  has_many :articles

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :provider_uid => auth.uid).first
    puts auth.info
    if user
      user.provider_token = auth.credentials.token
      user.provider_expires_at = Time.at(auth.credentials.expires_at)
      user.save
      return user
    else
      registered_user = User.where(:email => auth.info.email).first
      if registered_user
        registered_user.provider = auth.provider
        registered_user.provider_uid = auth.uid
        registered_user.provider_token = auth.credentials.token
        registered_user.provider_expires_at = Time.at(auth.credentials.expires_at)
        registered_user.save
        return registered_user
      else
        user = User.create( name:auth.info.name,
                            provider: auth.provider,
                            provider_uid: auth.uid,
                            email: auth.info.email,
                            password: Devise.friendly_token[0,20],
                            provider_token: auth.credentials.token,
                            provider_expires_at: Time.at(auth.credentials.expires_at)
                          )
      end
    end
  end

  def access_token
    if self.provider == "facebook"
      refresh_facebook_token
    end
    self.provider_token
  end

  def refresh_facebook_token
    # Checks the saved expiry time against the current time
    if self.provider_expires_at > Time.now
      # Get the new token
      new_token = facebook_oauth.exchange_access_token_info(self.provider_token)

      # Save the new token and its expiry over the old one
      self.provider_token = new_token['access_token']
      self.provider_expires_at = new_token['expires']
      save
    end
  end

  # Connect to Facebook via Koala's oauth
  def facebook_oauth
    # Insert your own Facebook client ID and secret here
    @facebook_oauth ||= Koala::Facebook::OAuth.new(Setting.facebook_auth_key.app_id, Setting.facebook_auth_key.app_secret)
  end
end
