class ChangeMemberUidSizeTo36 < ActiveRecord::Migration
  def up
    change_column :members, :uid, :string, limit: 36, null: false
  end

  def down
    change_column :members, :uid, :string, limit: 12, null: false
  end
end
