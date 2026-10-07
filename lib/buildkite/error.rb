module Buildkite
  # Base class for everything this library raises. Errors from the API carry the
  # response, so callers can read the status and body.
  class Error < StandardError
    attr_reader :response

    def initialize(message = nil, response: nil)
      super(message)
      @response = response
    end

    def status
      response&.status
    end

    def body
      response&.body
    end
  end

  class BadRequestError < Error; end
  class AuthenticationError < Error; end
  class ForbiddenError < Error; end
  class NotFoundError < Error; end
  class ConflictError < Error; end
  class UnprocessableEntityError < Error; end
  class ServerError < Error; end

  # Raised when the request couldn't be completed (timeout, connection refused, etc.)
  class ConnectionError < Error; end

  # Raised on a 429 once any retries are used up. retry_after is the number of
  # seconds Buildkite asked us to wait, if it said.
  class RateLimitError < Error
    def retry_after
      value = response&.headers&.[]("Retry-After") || response&.headers&.[]("RateLimit-Reset")
      Integer(value, exception: false)
    end
  end
end
