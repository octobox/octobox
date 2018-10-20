class AddShowAppBannerFlagToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :show_app_banner, :boolean, default: true
  end
end
