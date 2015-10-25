class AddAppIdToCredential < ActiveRecord::Migration
  def change
    add_column :credentials, :app_id, :integer
  end
end