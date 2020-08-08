if Rails.application.secrets.hirefire_token.present?
  HireFire::Resource.configure do |config|
    config.dyno(:worker) do
      HireFire::Macro::Sidekiq.queue
    end
  end
end
