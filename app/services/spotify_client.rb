# frozen_string_literal: true

require 'base64'
require 'json'
require 'net/http'
require 'uri'

class SpotifyClient
  API_BASE_URL = 'https://api.spotify.com'
  DEFAULT_LIMIT = 50

  def initialize(user_access_token: nil)
    @user_access_token = user_access_token
  end

  def followed_artists(after: nil, limit: DEFAULT_LIMIT)
    response = get(
      '/v1/me/following',
      token: @user_access_token,
      params: {
        type: 'artist',
        limit: limit,
        after: after
      }.compact
    )

    artists = response.fetch('artists', {})
    {
      items: Array(artists['items']),
      cursors: artists['cursors'] || {}
    }
  end

  def related_artists(spotify_artist_id)
    response = get(
      "/v1/artists/#{spotify_artist_id}/related-artists",
      token: self.class.app_access_token
    )

    Array(response['artists'])
  end

  def self.app_access_token
    if defined?(@app_access_token_expires_at) && @app_access_token.present? && @app_access_token_expires_at > Time.current
      return @app_access_token
    end

    token_data = request_app_access_token
    @app_access_token = token_data.fetch('access_token')
    expires_in = token_data.fetch('expires_in').to_i
    @app_access_token_expires_at = Time.current + [expires_in - 30, 30].max
    @app_access_token
  end

  def self.request_app_access_token
    client_id = ENV['CLIENT_ID'].to_s
    client_secret = ENV['CLIENT_SECRET'].to_s
    raise 'Spotify credentials are missing' if client_id.blank? || client_secret.blank?

    uri = URI.parse('https://accounts.spotify.com/api/token')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
    request.set_form_data(grant_type: 'client_credentials')

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    parse_json_response!(response)
  end

  private

  def get(path, token:, params: {})
    raise 'Spotify access token is missing' if token.blank?

    uri = URI.join(API_BASE_URL, path)
    uri.query = URI.encode_www_form(params) if params.present?

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{token}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    self.class.parse_json_response!(response)
  end

  def self.parse_json_response!(response)
    body = response.body.to_s
    parsed = body.present? ? JSON.parse(body) : {}
    return parsed if response.is_a?(Net::HTTPSuccess)

    error_message = parsed.is_a?(Hash) ? parsed.dig('error', 'message') || parsed['error_description'] : nil
    raise "Spotify API request failed (#{response.code}): #{error_message || body}"
  end
end
