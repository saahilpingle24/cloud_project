class AddExpirationToApiKeys < ActiveRecord::Migration
  def change
    add_column :api_keys, :expiration, :datetime
  end
end
