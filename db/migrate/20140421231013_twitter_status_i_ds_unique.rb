class TwitterStatusIDsUnique < ActiveRecord::Migration
  def change
    add_index :statuses, :twitter_status_id, unique: true
  end
end
