# frozen_string_literal: true

# == VerifiesWithEmail
#
# Controller concern to handle verification by email
module VerifiesWithEmail
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper

  included do
    prepend_before_action :verify_with_email, only: :create, unless: -> { skip_verify_with_email? }
    skip_before_action :required_signup_info, only: :successful_verification
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def verify_with_email
    return unless user = find_user || find_verification_user

    if session[:verification_user_id] && token = verification_params[:verification_token].presence
      # The verification token is submitted, verify it
      verify_token(user, token)
    elsif require_email_verification_enabled?(user)
      # Limit the amount of password guesses, since we now display the email verification page
      # when the password is correct, which could be a giveaway when brute-forced.
      return render_sign_in_rate_limited if check_rate_limit!(:user_sign_in, scope: user) { true }

      if user.valid_password?(user_params[:password])
        # The user has logged in successfully.

        if user.unlock_token
          # Prompt for the token if it already has been set
          prompt_for_email_verification(user)
        elsif user.access_locked? || !trusted_ip_address?(user)
          # require email verification if:
          # - their account has been locked because of too many failed login attempts, or
          # - they have logged in before, but never from the current ip address
          reason = 'sign in from untrusted IP address' unless user.access_locked?
          send_verification_instructions(user, reason: reason) unless send_rate_limited?(user)
          prompt_for_email_verification(user)
        end
      end
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def resend_verification_code
    return unless user = find_verification_user

    if send_rate_limited?(user)
      message = format(
        s_("IdentityVerification|You've reached the maximum amount of resends. Wait %{interval} and try again."),
        interval: rate_limit_interval(:email_verification_code_send)
      )
      render json: { status: :failure, message: message }
    else
      send_verification_instructions(user)
      render json: { status: :success }
    end
  end

  def successful_verification
    session.delete(:verification_user_id)
    @redirect_url = after_sign_in_path_for(current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    render layout: 'minimal'
  end

  private

  def skip_verify_with_email?
    two_factor_enabled? || Gitlab::Qa.request?(request.user_agent)
  end

  def find_verification_user
    return unless session[:verification_user_id]

    User.find_by_id(session[:verification_user_id])
  end

  def send_verification_instructions(user, reason: nil)
    service = Users::EmailVerification::GenerateTokenService.new(attr: :unlock_token, user: user)
    raw_token, encrypted_token = service.execute
    user.unlock_token = encrypted_token
    user.lock_access!({ send_instructions: false, reason: reason })
    send_verification_instructions_email(user, raw_token)
  end

  def send_verification_instructions_email(user, token)
    return unless user.can?(:receive_notifications)

    Notify.verification_instructions_email(user.email, token: token).deliver_later

    log_verification(user, :instructions_sent)
  end

  def verify_token(user, token)
    service = Users::EmailVerification::ValidateTokenService.new(attr: :unlock_token, user: user, token: token)
    result = service.execute

    if result[:status] == :success
      handle_verification_success(user)
      render json: { status: :success, redirect_path: users_successful_verification_path }
    else
      handle_verification_failure(user, result[:reason], result[:message])
      render json: result
    end
  end

  def render_sign_in_rate_limited
    message = format(
      s_('IdentityVerification|Maximum login attempts exceeded. Wait %{interval} and try again.'),
      interval: rate_limit_interval(:user_sign_in)
    )
    redirect_to new_user_session_path, alert: message
  end

  def rate_limit_interval(rate_limit)
    interval_in_seconds = Gitlab::ApplicationRateLimiter.rate_limits[rate_limit][:interval]
    distance_of_time_in_words(interval_in_seconds)
  end

  def send_rate_limited?(user)
    Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: user)
  end

  def handle_verification_failure(user, reason, message)
    user.errors.add(:base, message)
    log_verification(user, :failed_attempt, reason)
  end

  def handle_verification_success(user)
    user.unlock_access!
    log_verification(user, :successful)

    sign_in(user)

    log_audit_event(current_user, user, with: authentication_method)
    log_user_activity(user)
    verify_known_sign_in
  end

  def trusted_ip_address?(user)
    return true if Feature.disabled?(:check_ip_address_for_email_verification)

    AuthenticationEvent.initial_login_or_known_ip_address?(user, request.ip)
  end

  def prompt_for_email_verification(user)
    session[:verification_user_id] = user.id
    self.resource = user
    add_gon_variables # Necessary to set the sprite_icons path, since we skip the ApplicationController before_filters

    render 'devise/sessions/email_verification'
  end

  def verification_params
    params.require(:user).permit(:verification_token)
  end

  def log_verification(user, event, reason = nil)
    Gitlab::AppLogger.info(
      message: 'Email Verification',
      event: event.to_s.titlecase,
      username: user.username,
      ip: request.ip,
      reason: reason.to_s
    )
  end

  def require_email_verification_enabled?(user)
    Feature.enabled?(:require_email_verification, user) &&
      Feature.disabled?(:skip_require_email_verification, user, type: :ops)
  end
end
