module TicketmasterConfig
  module_function

  def api_key
    ENV['TICKETMASTER_API_KEY'].to_s.strip
  end

  def configured?
    key = api_key
    key.present? && !key.include?('your_') && key != 'demo'
  end
end
