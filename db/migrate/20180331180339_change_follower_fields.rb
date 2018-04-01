class ChangeFollowerFields < ActiveRecord::Migration[5.1]
  def change
    remove_column :followers, :source
  end
end
