require 'test_helper'

class OpenCollectiveTest < ActiveSupport::TestCase

	setup do
		@user = create(:user, github_login: 'andrew')
		@app = create(:app_installation, account_login: @user.github_login)

		@individual_plan = create(:subscription_plan, name: "Open Collective Individual")
    @org_plan = create(:subscription_plan, name: "Open Collective Organisation")
	end

	test "plans are set up" do
		assert_equal SubscriptionPlan.count, 2
	end

	test "gets subscriber names" do
		stub_oc_members_request
		transactions = Oj.load(Typhoeus.get("https://opencollective.com/octobox/members.json").body)

		names = Octobox::OpenCollective.get_sub_names(transactions, 10)
		
		assert_equal names.length, 4
		assert names.include?('tom')
	end

	test "adds new plans" do
		Octobox::OpenCollective.apply_plan([@user.github_login], @individual_plan.name)
		assert @user.has_personal_plan?
	end

	test "renews plans" do
		assert @user.has_personal_plan?
	end

	test "removes plans" do
		refute @user.has_personal_plan?
	end

	test "upgrades plans" do
		
	end
end
