class Follow < ActiveRecord::Base
  validates :twitter_follower_id, :twitter_followee_id, presence: true

  belongs_to :follower,
    class_name: 'User',
    foreign_key: :twitter_follower_id,
    primary_key: :twitter_user_id

  belongs_to :followee,
    class_name: 'User',
    foreign_key: :twitter_followee_id,
    primary_key: :twitter_user_id
end
