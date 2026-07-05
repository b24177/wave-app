# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

class TicketmasterClient
  ROOT_URL = 'https://app.ticketmaster.com/discovery/v2'.freeze
  TRIBUTE_KEYWORDS = ['tribute', 'karaoke', 'cover', 'lets sing', 'vs.'].freeze
  RELAXED_MIN_SCORE = 0.6

  def initialize(api_key: TicketmasterConfig.api_key)
    @api_key = api_key
  end

  def configured?
    @api_key.present?
  end

  def first_music_event_for(artist_name, country_code: 'US')
    return if artist_name.blank? || !configured?

    diagnostics = { artist: artist_name }
    attraction_id = find_attraction_id(artist_name)
    diagnostics[:attraction_id_found] = attraction_id.present?
    payload = attraction_id.present? ? event_search_by_attraction(attraction_id, country_code: country_code) : event_search_by_keyword(artist_name, country_code: country_code)
    diagnostics[:initial_event_count] = payload.dig('_embedded', 'events')&.size.to_i

    event, reason = select_best_event(payload.dig('_embedded', 'events'), artist_name)
    diagnostics[:initial_selection_reason] = reason
    if event.blank? && attraction_id.present?
      fallback_payload = event_search_by_keyword(artist_name, country_code: country_code)
      diagnostics[:keyword_fallback_event_count] = fallback_payload.dig('_embedded', 'events')&.size.to_i
      event, reason = select_best_event(fallback_payload.dig('_embedded', 'events'), artist_name)
      diagnostics[:keyword_fallback_reason] = reason
    end

    if event.blank?
      global_payload = attraction_id.present? ? event_search_by_attraction(attraction_id, country_code: nil) : event_search_by_keyword(artist_name, country_code: nil)
      diagnostics[:global_fallback_event_count] = global_payload.dig('_embedded', 'events')&.size.to_i
      event, reason = select_best_event(global_payload.dig('_embedded', 'events'), artist_name)
      diagnostics[:global_fallback_reason] = reason
    end

    diagnostics[:matched_event_name] = event&.dig('name')
    log_debug(diagnostics)

    build_event(event)
  end

  private

  def find_attraction_id(artist_name)
    payload = get(
      'attractions.json',
      keyword: artist_name,
      classificationName: 'music',
      sort: 'relevance,desc',
      size: 10
    )

    attractions = payload.dig('_embedded', 'attractions') || []
    exact_match = attractions.find { |entry| same_artist_name?(entry['name'], artist_name) }
    close_match = attractions.find { |entry| close_artist_name?(entry['name'], artist_name) }

    (exact_match || close_match)&.dig('id')
  end

  def event_search_by_keyword(artist_name, country_code:)
    params = {
      keyword: artist_name,
      classificationName: 'music',
      sort: 'date,asc',
      size: 20,
      startDateTime: Time.current.utc.iso8601
    }

    params[:countryCode] = country_code if country_code.present?
    get('events.json', params)
  end

  def event_search_by_attraction(attraction_id, country_code:)
    params = {
      attractionId: attraction_id,
      classificationName: 'music',
      sort: 'date,asc',
      size: 10,
      startDateTime: Time.current.utc.iso8601
    }

    params[:countryCode] = country_code if country_code.present?
    get('events.json', params)
  end

  def select_best_event(events, artist_name)
    return [nil, 'no_events'] if events.blank?

    strict_match = events.find { |event| event_matches_artist?(event, artist_name) }
    return [strict_match, 'strict_match'] if strict_match.present?

    relaxed_candidates = events.filter_map do |event|
      next if likely_tribute_or_cover?(event['name'])

      score = relaxed_match_score(event, artist_name)
      next if score < RELAXED_MIN_SCORE

      [event, score]
    end

    best_relaxed = relaxed_candidates.max_by { |entry| entry.last }
    return [best_relaxed.first, "relaxed_match(score=#{best_relaxed.last.round(2)})"] if best_relaxed.present?

    [nil, 'no_confident_match']
  end

  def log_debug(diagnostics)
    return unless ENV['TICKETMASTER_DEBUG_MATCHING'] == '1'

    Rails.logger.info("Ticketmaster matching: #{diagnostics}")
  end

  def event_matches_artist?(event, artist_name)
    return false if event.blank?
    return false if likely_tribute_or_cover?(event['name'])

    attraction_names = event.dig('_embedded', 'attractions')&.map { |entry| entry['name'] }.to_a
    attraction_names.any? do |name|
      same_artist_name?(name, artist_name) || close_artist_name?(name, artist_name)
    end
  end

  def likely_tribute_or_cover?(title)
    normalized = normalize_name(title)
    TRIBUTE_KEYWORDS.any? { |word| normalized.include?(word) }
  end

  def same_artist_name?(candidate, artist_name)
    normalize_name(candidate) == normalize_name(artist_name)
  end

  def close_artist_name?(candidate, artist_name)
    match_score(candidate, artist_name) >= 0.8
  end

  def relaxed_match_score(event, artist_name)
    attraction_names = event.dig('_embedded', 'attractions')&.map { |entry| entry['name'] }.to_a
    return 0.0 if attraction_names.empty?

    attraction_names.map { |name| match_score(name, artist_name) }.max || 0.0
  end

  def match_score(candidate, artist_name)
    candidate_tokens = tokens(candidate)
    artist_tokens = tokens(artist_name)
    return 0.0 if candidate_tokens.empty? || artist_tokens.empty?

    overlap = (candidate_tokens & artist_tokens).size.to_f
    recall = overlap / artist_tokens.size
    precision = overlap / candidate_tokens.size
    [recall, precision].min
  end

  def tokens(value)
    normalize_name(value).split
  end

  def normalize_name(value)
    value.to_s.downcase.gsub(/[^a-z0-9]+/, ' ').strip
  end

  def build_event(event)
    return if event.blank?

    {
      name: event['name'],
      starts_at: event.dig('dates', 'start', 'dateTime') || event.dig('dates', 'start', 'localDate'),
      venue: event.dig('_embedded', 'venues', 0, 'name'),
      city: event.dig('_embedded', 'venues', 0, 'city', 'name'),
      ticket_url: event['url'],
      image_url: select_image(event['images'])
    }
  end

  def select_image(images)
    return if images.blank?

    image = images.min_by do |entry|
      (entry['width'].to_i - 640).abs + (entry['height'].to_i - 360).abs
    end
    image&.[]('url')
  end

  def get(path, params)
    uri = URI("#{ROOT_URL}/#{path}")
    uri.query = URI.encode_www_form(params.merge(apikey: @api_key))

    response = Net::HTTP.get_response(uri)
    return {} unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.warn("Ticketmaster request failed: #{e.class} #{e.message}")
    {}
  end
end
