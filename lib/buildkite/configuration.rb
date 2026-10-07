# frozen_string_literal: true

module Buildkite
  class Configuration

    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_MAX_RETRIES = 2
    DEFAULT_MAX_RETRY_WAIT = 60

    attr_accessor :token
    attr_accessor :org
    attr_accessor :pipeline

    # Seconds to wait for a response, and for the connection to open
    attr_accessor :timeout
    attr_accessor :open_timeout

    # How many times to retry a request that was rate limited (429), waiting for the
    # time Buildkite asks for. Set to 0 to raise Buildkite::RateLimitError straight away.
    attr_accessor :max_retries

    # If Buildkite asks us to wait longer than this many seconds, raise instead of waiting
    attr_accessor :max_retry_wait

    # The Faraday adapter, e.g. [:test, stubs] in tests
    attr_accessor :adapter

    def initialize
      @timeout = DEFAULT_TIMEOUT
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @max_retries = DEFAULT_MAX_RETRIES
      @max_retry_wait = DEFAULT_MAX_RETRY_WAIT
      @adapter = Faraday.default_adapter
    end

  end
end
