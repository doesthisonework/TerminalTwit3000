require 'open-uri'

class Status < ActiveRecord::Base
  validates :body, :twitter_status_id, :twitter_user_id, presence: true
  validates :twitter_status_id, uniqueness: true

  belongs_to :user,
    class_name: 'User',
    foreign_key: :twitter_user_id,
    primary_key: :twitter_user_id

  def self.fetch_by_twitter_user_id!(twitter_user_id)
    statuses = TwitterSession.get('statuses/user_timeline', user_id: twitter_user_id)

    saved_status_ids = Status.where(
      twitter_user_id: statuses.first['user']['id_str'] ).
      pluck( :twitter_status_id )

    new_statuses = statuses.select do |status|
      !saved_status_ids.include?(status['id_str'])
    end

    statuses.each { |status| parse_status(status) }
  end

  def self.parse_status(status)
    twitter_status_id = status['id_str']
    twitter_user_id = status['user']['id_str']
    body = status['text']
    Status.create(twitter_status_id: twitter_status_id,
               twitter_user_id: twitter_user_id, body: body)
  end

  def self.post(body)
    status = TwitterSession.post( 'statuses/update', status: body )
    parse_json(status)
  end

  def self.get_by_twitter_user_id(twitter_user_id)
    fetch_by_twitter_user_id!(twitter_user_id) if internet_connection?
    Status.where(twitter_user_id: twitter_user_id)
  end

  def fetch_statuses!
    Status.fetch_by_twitter_user_id!(self.twitter_user_id)
  end

  private

  # from http://stackoverflow.com/questions/2385186/check-if-internet-connection-exists-with-ruby
  def self.internet_connection?
    begin
      true if open("http://www.google.com/")
    rescue
      false
    end
  end
end
