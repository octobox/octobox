# frozen_string_literal: true
class OpenCollectiveController < ApplicationController
  def callback
    transaction_id = params[:transactionid]
    transaction = Octobox::OpenCollective.load_transaction()

    if transaction
      plan = SubscriptionPlan.find_by_name('Open Collective Individual')
      subscription_purchase = SubscriptionPurchase.new(account_id: current_user.github_id,
                                                       unit_count: 1,
                                                       subscription_plan: plan,
                                                       oc_transactionid: transaction_id)

      if subscription_purchase.save
        redirect_to root_path, notice: 'Your account has been upgraded'
      else
        redirect_to pricing_path, error: 'There was an error with your donation, please contact support@octobox.io'
      end
    else
      redirect_to pricing_path, error: 'There was an error with your donation, please contact support@octobox.io'
    end
  end
end
