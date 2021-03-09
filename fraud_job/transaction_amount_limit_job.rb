module FraudCheck
  class TransactionAmountLimitJob < FraudCheckJob
    def check_limits
      @dataset = FraudCheck::TransactionAmountLimit.eager_graph(:merchant).all
      check_limit :limit_amount_positive_day, :amount_positive_day
      check_limit :limit_amount_positive_week, :amount_positive_week
      check_limit :limit_amount_negative_day, :amount_negative_day
      check_limit :limit_amount_negative_week, :amount_negative_week
    end
  end
end
