module FraudCheck
  class FraudCheckJob < TogetherworkJob
    attr_accessor :alerts, :dataset, :client

    def initialize
      super
      api_key = 'api_key_string'
      @client = Clients::OpsGenie::OpsGenieClient.new({ api_key: api_key })
      @alerts = {}
      Affiliate.all.map { |a| @alerts[a.affiliate_name.to_sym] = [] }
    end

    def process
      Sequel::Model.db.with_server(replica_server) { check_limits }
      send_alerts
    end

    def check_limits
      raise NotImplementedError, "#{__method__} not implemented - #{self.class}"
    end

    def check_limit(limit, value)
      dataset.each do |row|
        next if row[limit].nil? || row[value].nil?

        generate_alert(limit, value, row) if row[limit].to_d <= row[value]
      end
    end

    def generate_alert(limit, value, fraud)
      msg = <<~MSG.squish
        #{fraud.merchant.merchant_name} (#{fraud.merchant.reference_token})
        #{value.to_s.titleize} Limit of #{format_number(fraud[limit])} exceeded!
        Transaction #{value.to_s.titleize}: #{format_number(fraud[value])}
      MSG
      add_alert fraud, msg
    end

    def add_alert(fraud, msg)
      @alerts[fraud.merchant.affiliate.affiliate_name.to_sym] << msg
    end

    def send_alerts
      alerts.each_key do |affiliate_name|
        next unless alerts[affiliate_name].any?

        body = alert_body(affiliate_name, alerts[affiliate_name])
        response = client.create_alert(body)
        alert_id = JSON.parse(response)['requestId']
        log_success alert_id unless alert_id.nil?
      end
    end

    def alert_body(affiliate_name, messages)
      {
        message: message_and_alias(affiliate_name),
        alias: message_and_alias(affiliate_name),
        description: messages.join("\n"),
        tags: ['Togetherpay'],
        source: 'Togetherpay Fraud Monitor',
        priority: 'P1'
      }
    end

    def message_and_alias(affiliate_name)
      msg = "Potential Fraud Alert for #{affiliate_name}"
      return "TEST: #{msg}" unless Rails.env.production?

      msg
    end

    def log_success(alert_id)
      log "Alert Creation Successful: #{alert_id}", color: :cyan
    end

    def format_number(val)
      return val if self.class.to_s.include? 'Count'

      val = val.to_s.to_d
      Money.new((val * 100), 'USD').format(sign_before_symbol: true)
    end

    def replica_server
      READ_ONLY_DB
    end
  end
end
