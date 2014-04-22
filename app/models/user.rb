class User < ActiveRecord::Base
  attr_accessible :twitter_user_id, :screen_name

  validates :screen_name, :twitter_user_id, presence: true, uniqueness: true

  has_many  :statuses,
            class_name: 'Status',
            foreign_key: :twitter_user_id,
            primary_key: :twitter_user_id

  has_many  :outbound_follows,
            class_name: 'Follow',
            foreign_key: :twitter_follower_id,
            primary_key: :twitter_user_id

  has_many  :inbound_follows,
            class_name: 'Follow',
            foreign_key: :twitter_followee_id,
            primary_key: :twitter_user_id

    has_many :followed_users, through: :outbound_follows, source: :followee

    has_many :followers, through: :inbound_follows, source: :follower

  def self.fetch_by_screen_name!(screen_name)
    user = TwitterSession.get(
      '/users/show', 
      screen_name: screen_name
    )
    parse_twitter_user(user)
  end

  def self.get_by_screen_name(screen_name)
    User.find_by_screen_name(screen_name) || fetch_by_screen_name!(screen_name)
  end

  def self.parse_twitter_user(user)
    screen_name = user['screen_name']
    twitter_user_id = user['id_str']
    User.create(screen_name: screen_name, twitter_user_id: twitter_user_id)
  end

  def self.fetch_by_ids(ids)
    existing_users = User.where(twitter_user_id: ids)
    existing_users_ids = existing_users.map(&:twitter_user_id)

    new_ids = ids.reject { |id| existing_users_ids.include?(id) }
    
    raise "too many users for one query" if new_ids.length > 100

    new_users = []
    unless new_ids.empty?
      new_user_params = TwitterSession.post(
        '/users/lookup', 
        user_id: new_ids.join(',')
      )

      new_users = new_user_params.map { |user| User.parse_twitter_user(user) }
    end 

    existing_users + new_users
  end

  def sync_followers
    fetched_followers = self.fetch_followers
    fetched_followers.each do |fetched_follower|
      fetched_follower.save! unless fetched_follower.persisted?
    end

    self.followers = fetched_followers
  end

  def fetch_followers
    followers_ids = TwitterSession.get(
      '/followers/ids', 
      { user_id: self.twitter_user_id, stringify_ids: 'true' }
    )['ids']
    
    User.fetch_by_ids(followers_ids)
  end

end
