namespace :opencollective do

  period = 1.month.ago
  subs_cost_per_period = 100
	
	desc "Sync supporters"
  task sync_supporters: :environment do
  	
    require 'open-uri'
		
    response = JSON.parse(open("https://opencollective.com/octobox/members.json"))
  	txs = response.select do |item| 
  		Date.parse(item["lastTransactionAt"]) > period &&
  		item["github"].present? || item["organization"].present?
  	end

    # check for users who have made multiple donations in the last month that tipped
    tx_groups = txs.group_by{|item| item["github"].presence || item["organization"]}
    subs = tx_groups.select do |_name, transactions|
      transactions.sum{|item| item['lastTransactionAmount']} >= subs_cost_per_period
    end

  	subnames = subs.map do |name, _transactions|
      # TODO make sure it's clear that you need to add your GH url or GH org name
      rz = name.match(/github.com\/(\w+)\//i) if name
      rz[1] if rz
  	end.compact

    plan = SubscriptionPlan.find_by_name('Open Collective Private')
    current_subs_purchases = plan.subscription_purchases.where(unit_count: 1) unless plan.nil?
    if current_subs_purchases 
      current_subs_purchases.each do |purchase|
        unless subnames.include? purchase.app_installation.account_login
          purchase.update_attributes(unit_count: 0)
          Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Removed open collective subscription purchase for #{purchase.app_installation.account_login}\033[0m\n\n")
        end
      end
    end

    subnames.each do |subscriber|
      
      app_installation = AppInstallation.find_by_account_login(subscriber)
      
      next if app_installation.nil?
      
      subscription_purchase = app_installation.subscription_purchase

      if subscription_purchase.nil?
        app_installation.subscription_purchase.create(plan: plan, unit_count: 1)
        Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Added open collective subscription purchase for #{subscriber}\033[0m\n\n")
      elsif subscription_purchase.unit_count.zero? 
        subscription_purchase.update_attributes(plan: plan, unit_count: 1)
        Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Restarted open collective subscription purchase for #{subscriber}\033[0m\n\n")
      else
        Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Renewed open collective subscription purchase for #{subscriber}\033[0m\n\n")
      end
    end

  end

end