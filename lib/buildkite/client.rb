module Buildkite
  class Client

    BASE_URL = "https://api.buildkite.com/v2"

    ERROR_CLASSES = {
      400 => [BadRequestError, "Your request was malformed."],
      401 => [AuthenticationError, "You did not supply valid authentication credentials."],
      403 => [ForbiddenError, "You are not allowed to perform that action."],
      404 => [NotFoundError, "No results were found for your request."],
      409 => [ConflictError, "Your request was a conflict."],
      422 => [UnprocessableEntityError, "Unprocessable Content."],
      429 => [RateLimitError, "Your request exceeded the API rate limit."],
      500 => [ServerError, "We were unable to perform the request due to server-side problems."],
      501 => [ServerError, "This resource has not been implemented."]
    }.freeze

    class << self

      def connection
        key = [Buildkite.config.adapter, Buildkite.config.timeout, Buildkite.config.open_timeout]

        if @connection.nil? || @connection_key != key
          @connection_key = key
          @connection = build_connection
        end

        @connection
      end

      def reset!
        @connection = nil
      end

      def get_request(url, params: {}, headers: {})
        request { connection.get(url, params, headers) }
      end

      def post_request(url, body: {}, headers: {})
        request { connection.post(url, body, headers) }
      end

      def put_request(url, body: {}, headers: {})
        request { connection.put(url, body, headers) }
      end

      def patch_request(url, body: {}, headers: {})
        request { connection.patch(url, body, headers) }
      end

      def delete_request(url, headers: {})
        request { connection.delete(url, nil, headers) }
      end

      def handle_response(response)
        return true if response.status == 204

        raise error_for(response) if response.status >= 400

        response
      end

      private

      def build_connection
        Faraday.new(BASE_URL) do |conn|
          # A lambda, so a token set or changed after the first request is picked up
          conn.request :authorization, :Bearer, -> { Buildkite.config.token }

          conn.headers = {
            "User-Agent" => "buildkiterb/v#{VERSION} (github.com/d34ndev/buildkiterb)"
          }

          conn.options.timeout = Buildkite.config.timeout
          conn.options.open_timeout = Buildkite.config.open_timeout

          conn.request :json

          conn.response :json, content_type: "application/json"

          conn.adapter(*Buildkite.config.adapter)
        end
      end

      # Runs the block, waiting and trying again if we're rate limited
      def request
        retries = 0

        loop do
          response = begin
            yield
          rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
            raise ConnectionError, "#{e.class}: #{e.message}"
          end

          if response.status == 429 && retries < Buildkite.config.max_retries
            wait = retry_wait(response)

            if wait && wait <= Buildkite.config.max_retry_wait
              retries += 1
              sleep wait
              next
            end
          end

          return handle_response(response)
        end
      end

      # Seconds to wait before retrying. Buildkite sends RateLimit-Reset on every
      # response, which is the number of seconds until the limit resets.
      def retry_wait(response)
        value = response.headers["Retry-After"] || response.headers["RateLimit-Reset"]
        seconds = Integer(value, exception: false)
        seconds.nil? ? 1 : [seconds, 0].max
      end

      def error_for(response)
        klass, text = ERROR_CLASSES[response.status]
        klass ||= response.status >= 500 ? ServerError : Error
        text ||= response.status >= 500 ? "Buildkite is unavailable." : "The request failed."

        klass.new("Error #{response.status}: #{text} '#{error_message(response)}'", response: response)
      end

      def error_message(response)
        body = response.body
        body.is_a?(Hash) ? body["message"] : body.to_s[0, 200]
      end

    end

  end
end
