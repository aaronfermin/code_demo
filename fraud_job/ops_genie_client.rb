module Clients
  module OpsGenie
    class OpsGenieClient
      OPSGENIE_API_BASE_URL = 'https://api.opsgenie.com/v2'
      attr_accessor :api_key, :url

      def initialize(opts = {})
        opts.each { |k, v| send("#{k}=", v) if respond_to? "#{k}=" }
        @url ||= OPSGENIE_API_BASE_URL
        raise '[OpsGenie Error] No API key provided' if api_key.nil?
      end

      def create_alert(body)
        request = {
          method: 'POST',
          url: "#{url}/alerts",
          headers: headers('POST'),
          payload: body
        }
        send_request request
      end

      def list_alerts
        request = {
          method: 'GET',
          url: "#{url}/alerts",
          headers: headers('GET')
        }
        send_request request
      end

      private

      def send_request(request)
        request[:payload] = check_json request[:payload]
        RestClient::Request.execute request
      end

      def headers(protocol)
        ct = 'application/json'
        headers = { Authorization: "GenieKey #{api_key}" }
        headers[:content_type] = ct if %w[POST PATCH].include? protocol.upcase
        headers
      end

      def check_json(val)
        return val.to_json if val.is_a? Hash

        val
      end
    end
  end
end
