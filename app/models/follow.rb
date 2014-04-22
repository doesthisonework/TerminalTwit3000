class Follow < ActiveRecord::Base
  attr_accessible :twitter_followee_id, :twitter_follower_id

  validates :twitter_follower_id, :twitter_followee_id, presence: true

  belongs_to  :follower,
              class_name: 'User',
              foreign_key: :twitter_follower_id,
              primary_key: :twitter_user_id

  belongs_to  :followee,
              class_name: 'User',
              foreign_key: :twitter_followee_id,
              primary_key: :twitter_user_id
end
