require 'yaml'

class TwitterSession
  CONSUMER_KEY = File.read(Rails.root.join('.api_key')).chomp
  CONSUMER_SECRET = File.read(Rails.root.join('.api_secret')).chomp
  CONSUMER = OAuth::Consumer.new(
    CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")
  TOKEN_FILE = "access_token.yml"

  def self.get(path, query_values)
    url = path_to_url(path, query_values)

    JSON.parse(access_token.get(url).body)
  end

  def self.post(path, req_params)
    url = path_to_url(path, req_params)

    JSON.parse(access_token.post(url).body)
  end

  def self.access_token
      # Load from file or request from Twitter as necessary. Store token
      # in class instance variable so it is not repeatedly re-read from disk
      # unnecessarily.

      # We can serialize token to a file, so that future requests don't
        # need to be reauthorized.

    if File.exist?(TOKEN_FILE)
      # reload token from file
      @token = File.open(TOKEN_FILE) { |f| YAML.load(f) }
    else
      # copy the old code that requested the access token into a
      # `request_access_token` method.
      access_token = request_access_token
      File.open(TOKEN_FILE, "w") { |f| YAML.dump(access_token, f) }

      @token = access_token
    end
  end

  def self.request_access_token
    # Put user through authorization flow; save access token to file

    # "Consumer" in Twitter terminology means "client" in our discussion.
    # God only knows who thought it was a good idea to make up many terms
    # for the same thing.

    # An `OAuth::Consumer` object can make requests to the service on
    # behalf of the client application.


    # Ask service for a URL to send the user to so that they may authorize
    # us.
    request_token = CONSUMER.get_request_token
    authorize_url = request_token.authorize_url

    # Launchy is a gem that opens a browser tab for us
    puts "Go to this URL: #{authorize_url}"
    Launchy.open(authorize_url)

    # Because we don't use a redirect URL; user will receive a short PIN
    # (called a **verifier**) that they can input into the client
    # application. The client asks the service to give them a permanent
    # access token to use.
    puts "Login, and type your verification code in"
    oauth_verifier = gets.chomp
    access_token = request_token.get_access_token(
      :oauth_verifier => oauth_verifier
    )

    access_token
  end

  def self.path_to_url(path, query_values = nil)
    # All Twitter API calls are of the format
    # "https://api.twitter.com/1.1/#{path}.json". Use
    # `Addressable::URI` to build the full URL from just the
    # meaningful part of the path (`statuses/user_timeline`)
    Addressable::URI.new(
      scheme: 'https',
      host: 'api.twitter.com',
      path: "/1.1/#{path}.json",
      query_values: query_values
    ).to_s
  end

end