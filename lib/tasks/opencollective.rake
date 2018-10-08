namespace :opencollective do

  #https://github.com/octobox/octobox/commit/59311af84b9cadf9e4e7663270d60b82e64315ec
  period = 1.month.ago
  subs_cost_per_period = 100
	
	desc "Sync supporters"
  task sync_supporters: :environment do
  	require 'open-uri'
  	# download backers from https://github.com/opencollective/opencollective/blob/master/docs/api/collectives.md#get-members
		response = JSON.parse(open("https://opencollective.com/octobox/members.json"))
  	# parse the json stripping and transaction in the last month over 100USD
  	txs = response.select do |item| 
  		Date.parse(item["lastTransactionAt"]) > period &&
  		item["github"].present? || item["organization"].present?
  	end

    # we only want users who paid a total of 100 or more this month
    tx_groups = txs.group_by{|item| item["github"].presence || item["organization"]}
    subs = tx_groups.select do |name, transactions|
      transactions.sum{|item| item['lastTransactionAmount']} >= subs_cost_per_period
    end

  	subnames = subs.map do |name, _transactions|
      # TODO make sure it's clear that you need to add your GH url or GH org name
      # TODO check whether github names added to the account get added to the tx log in the api
      # match this to account names
      rz = name.match(/github.com\/(\w+)\//i) if name
      rz[1] if rz
  	end.compact

  	#find all the people on the plan not in subs and remove them!
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

    # update/add a subscription 
    subnames.each do |subscriber|
      # find the app installation by account_login
      #assume app installed, and find it
      app_installation = AppInstallation.find_by_account_login(subscriber)
      #log this skip
      next if app_installation.nil?
      # create SubscriptionPurcahse account_id: = AppInstallation.account_id
      subscription_purchase = app_installation.subscription_purchase
      # subscription plan.id == opencollective plan in db (find or create by name)
      if subscription_purchase.nil? 
        app_installation.subscription_purchase.create(plan: plan, unit_count: 1)
        Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Added open collective subscription purchase for #{subscriber}\033[0m\n\n")
      elsif subscription_purchase.unit_count.zero?
        subscription_purchase.update_attributes(plan: plan, unit_count: 1)
        Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Restarted open collective subscription purchase for #{subscriber}\033[0m\n\n")
      else
        Rails.logger.info("n\n\033[32m[#{Time.current}] INFO -- Renewed open collective subscription purchase for #{subscriber}\033[0m\n\n")
      end
      # log successful subs
    end

  end

end