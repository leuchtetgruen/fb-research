class Conf
  OAUTH_TOKEN = ENV['OAUTH_TOKEN'] || ""
  QUERY_DATA = false
  DEBUG =  false
  MAX_DEPTH = 5
  WAIT_SECONDS = 0.5
  DO_WAIT_AFTER_EACH_REQUEST = false

  def self.check
    if OAUTH_TOKEN.strip.length == 0
      puts "No valid OAUTH_TOKEN provided in environment"
      false
    else
      true
    end
  end
end
