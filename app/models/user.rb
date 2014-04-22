class User < ActiveRecord::Base
  validates :screen_name, :twitter_user_id, presence: true, uniqueness: true

  has_many :statuses,
    class_name: 'Status',
    foreign_key: :twitter_user_id,
    primary_key: :twitter_user_id

  has_many :outbound_follows,
    class_name: 'Follow',
    foreign_key: :twitter_followee_id,
    primary_key: :twitter_user_id

  has_many :inbound_follows,
    class_name: 'Follow',
    foreign_key: :twitter_follower_id,
    primary_key: :twitter_user_id

    has_many :followed_users, through: :outbound_follows, source: :followee

    has_many :followers, through: :inbound_follows, source: :follower

  def self.fetch_by_screen_name!(screen_name)
    user = TwitterSession.get('/users/show', screen_name: screen_name)
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

    new_ids = ids.select do |id|
      !existing_users.map(&:twitter_user_id).include?(id)
    end

    new_users = TwitterSession.get('/users/lookup', user_id: new_ids.join(',')).map do |user|
      parse_twitter_user(user)
    end

    existing_users + new_users
  end

end
