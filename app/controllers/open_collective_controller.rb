# frozen_string_literal: true
class OpenCollectiveController < ApplicationController
  before_action :check_octobox_io

  def callback
    transaction_id = params[:transactionid]
    transaction = Octobox::OpenCollective.load_transaction(transaction_id)

    if transaction && transaction["result"] && transaction["result"]["amount"] >= 1000
      plan = SubscriptionPlan.find_by_name('Open Collective Individual')
      subscription_purchase = SubscriptionPurchase.new(account_id: current_user.github_id,
                                                       unit_count: 1,
                                                       subscription_plan: plan,
                                                       oc_transactionid: transaction_id)

      if subscription_purchase.save
        redirect_to root_path, flash: {success: "Subscription updated. Remember to <a href='#{Octobox.config.app_install_url}'>install the GitHub app</a> on repositories (may require additional authority) "}
      else
        redirect_to pricing_path, flash: {error: 'There was an error with your donation, please contact support@octobox.io'}
      end
    else
      redirect_to pricing_path, flash: {error: 'There was an error with your donation, please contact support@octobox.io'}
    end
  end
end
