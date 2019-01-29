namespace :opencollective do

  period = 1.month.ago
  individual_cost_per_period = 10
  organisation_cost_per_period = 100
	
	desc "Sync supporters"
  task sync_supporters: :environment do
  	
    require 'open-uri'
		
    response = JSON.parse(open("https://opencollective.com/octobox/members.json"))
  	txs = response.select do |item| 
  		Date.parse(item["lastTransactionAt"]) > period && item["github"].present?
  	end

    # check for users who have made multiple donations in the last month that tipped the jar
    tx_groups = txs.group_by{|item| item["github"].presence}
    subs = tx_groups.select do |_name, transactions|
      transactions.sum{|item| item['lastTransactionAmount']} >= organisation_cost_per_period
    end

  	subnames = subs.map do |name, _transactions|
      rz = name.match(/github.com\/(\w+)\//i) if name
      rz[1] if rz
  	end.compact

    # grab the appropriate plan
    plan_name = 'Open Collective Organisation'
    plan = SubscriptionPlan.find_by_name(plan_name)
    Rails.logger.info("n\n\033[32m[#{Time.current}] ERROR -- Could not find plan named #{plan_name}\033[0m\n\n") if plan.nil?

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