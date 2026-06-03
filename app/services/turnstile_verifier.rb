# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Encapsulate Cloudflare Turnstile siteverify calls.
require 'json'
require 'net/http'

class TurnstileVerifier
  SITEVERIFY_URI = URI('https://challenges.cloudflare.com/turnstile/v0/siteverify').freeze

  def initialize(secret_key:, response_token:, remote_ip:)
    @secret_key = secret_key
    @response_token = response_token
    @remote_ip = remote_ip
  end

  def valid?
    return false if @secret_key.blank? || @response_token.blank?

    response = perform_request
    return false unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    body.is_a?(Hash) && body['success'] == true
  rescue JSON::ParserError => e
    Rails.logger.error("[TURNSTILE] Unable to parse verification response: #{e.message}")
    false
  rescue StandardError => e
    Rails.logger.error("[TURNSTILE] Verification request failed: #{e.message}")
    false
  end

  private

  def perform_request
    http = Net::HTTP.new(SITEVERIFY_URI.host, SITEVERIFY_URI.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(SITEVERIFY_URI.path)
    request.set_form_data(
      'secret' => @secret_key,
      'response' => @response_token,
      'remoteip' => @remote_ip
    )

    http.request(request)
  end
end
