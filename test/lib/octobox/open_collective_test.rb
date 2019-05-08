require 'test_helper'

class OpenCollectiveTest < ActiveSupport::TestCase

	setup do
		stub_oc_members_request
		@user = create(:user, github_login: 'andrew', github_id: '12345')
		@app = create(:app_installation, account_login: @user.github_login, account_id: @user.github_id)

		@individual_plan = create(:subscription_plan, name: "Open Collective Individual")
		@org_plan = create(:subscription_plan, name: "Open Collective Organisation")
	end

	test "plans are set up" do
		assert_equal SubscriptionPlan.count, 2
	end

	test "gets subscriber names" do
		transactions = Oj.load(Typhoeus.get("https://opencollective.com/octobox/members.json").body)

		Timecop.freeze(Time.local(2019, 4, 13)) do
			names = Octobox::OpenCollective.get_sub_names(transactions, 10)

			assert_equal names.length, 4
			assert names.include?('tom')
		end
	end

	test "adds new plans" do
		Octobox::OpenCollective.apply_plan([@user.github_login], @individual_plan.name)
		assert @user.has_personal_plan?
	end

	test "renews plans" do
		create(:subscription_purchase, account_id: @user.github_id, subscription_plan_id: @individual_plan.id, unit_count: 0)
		Octobox::OpenCollective.apply_plan([@user.github_login], @individual_plan.name)
		assert @user.has_personal_plan?
	end

	test "removes plans" do
		create(:subscription_purchase, account_id: @user.github_id, subscription_plan_id: @individual_plan.id, unit_count: 1)
		@another_user = create(:user, github_login: 'billy', github_id: '5678')
		create(:app_installation, account_login: @another_user.github_login, account_id: @another_user.github_id)
		create(:subscription_purchase, account_id: @another_user.github_id, subscription_plan_id: @individual_plan.id, unit_count: 1, next_billing_date: Time.now + 1.week)

		Octobox::OpenCollective.sync

		refute @user.has_personal_plan?
		assert @another_user.has_personal_plan?
	end

	test "upgrades plans" do

		@another_user = create(:user, github_login: 'benjam', github_id: '5678')
		create(:app_installation, account_login: @another_user.github_login, account_id: @another_user.github_id)
		create(:subscription_purchase, account_id: @another_user.github_id, subscription_plan_id: @individual_plan.id, unit_count: 1)

		Octobox::OpenCollective.sync

		assert_equal SubscriptionPurchase.find_by_account_id(@another_user.github_id).subscription_plan.name, @org_plan.name
	end
end
