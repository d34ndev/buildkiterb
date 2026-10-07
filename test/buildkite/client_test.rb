require "test_helper"

class ClientTest < Minitest::Test

  # These tests stub HTTP with Faraday's test adapter instead of using cassettes
  def setup
    @config = Buildkite.config
    @original = {token: @config.token, adapter: @config.adapter, max_retries: @config.max_retries}
    @stubs = Faraday::Adapter::Test::Stubs.new
    @config.adapter = [:test, @stubs]
    @config.max_retries = 2
    @sleeps = []
    VCR.turn_off!
  end

  def teardown
    VCR.turn_on!
    @config.token = @original[:token]
    @config.adapter = @original[:adapter]
    @config.max_retries = @original[:max_retries]
    Buildkite::Client.reset!
  end

  def json(body = {}, status: 200, headers: {})
    [status, {"Content-Type" => "application/json"}.merge(headers), body.to_json]
  end

  def get(path = "user")
    Buildkite::Client.stub(:sleep, ->(seconds) { @sleeps << seconds }) do
      Buildkite::Client.get_request(path)
    end
  end

  def test_sends_current_token
    seen = []
    @stubs.get("/v2/user") { |env| seen << env.request_headers["Authorization"]; json }

    @config.token = "first"
    get
    @config.token = "second"
    get

    assert_equal ["Bearer first", "Bearer second"], seen
  end

  def test_no_content_returns_true
    @stubs.delete("/v2/access-token") { [204, {}, ""] }
    assert_equal true, Buildkite::Client.delete_request("access-token")
  end

  {
    400 => Buildkite::BadRequestError,
    401 => Buildkite::AuthenticationError,
    403 => Buildkite::ForbiddenError,
    404 => Buildkite::NotFoundError,
    409 => Buildkite::ConflictError,
    422 => Buildkite::UnprocessableEntityError,
    500 => Buildkite::ServerError,
    502 => Buildkite::ServerError,
    503 => Buildkite::ServerError,
    418 => Buildkite::Error
  }.each do |status, error_class|
    define_method("test_#{status}_raises_#{error_class.name.split("::").last}") do
      @stubs.get("/v2/user") { json({message: "Nope"}, status: status) }

      error = assert_raises(error_class) { get }

      assert_equal status, error.status
      assert_equal "Nope", error.body["message"]
      assert_includes error.message, "Error #{status}"
      assert_includes error.message, "'Nope'"
    end
  end

  def test_errors_inherit_from_error
    assert Buildkite::NotFoundError < Buildkite::Error
    assert Buildkite::RateLimitError < Buildkite::Error
  end

  def test_non_json_error_body
    @stubs.get("/v2/user") { [502, {"Content-Type" => "text/html"}, "<html>Bad Gateway</html>"] }

    error = assert_raises(Buildkite::ServerError) { get }
    assert_includes error.message, "Bad Gateway"
  end

  def test_rate_limit_retries_then_succeeds
    calls = 0
    @stubs.get("/v2/user") do
      calls += 1
      calls < 3 ? json({message: "Slow down"}, status: 429, headers: {"Retry-After" => "3"}) : json({id: 1})
    end

    assert_equal 1, get.body["id"]
    assert_equal 3, calls
    assert_equal [3, 3], @sleeps
  end

  def test_rate_limit_uses_ratelimit_reset
    calls = 0
    @stubs.get("/v2/user") do
      calls += 1
      calls == 1 ? json({}, status: 429, headers: {"RateLimit-Reset" => "7"}) : json
    end

    get
    assert_equal [7], @sleeps
  end

  def test_rate_limit_raises_when_retries_used_up
    @stubs.get("/v2/user") { json({message: "Slow down"}, status: 429, headers: {"Retry-After" => "2"}) }

    error = assert_raises(Buildkite::RateLimitError) { get }

    assert_equal 2, error.retry_after
    assert_equal 2, @sleeps.size
  end

  def test_rate_limit_does_not_retry_when_disabled
    @config.max_retries = 0
    @stubs.get("/v2/user") { json({}, status: 429) }

    assert_raises(Buildkite::RateLimitError) { get }
    assert_empty @sleeps
  end

  def test_rate_limit_does_not_wait_longer_than_max_retry_wait
    @stubs.get("/v2/user") { json({}, status: 429, headers: {"Retry-After" => "3600"}) }

    assert_raises(Buildkite::RateLimitError) { get }
    assert_empty @sleeps
  end

  def test_timeout_raises_connection_error
    @stubs.get("/v2/user") { raise Faraday::TimeoutError }

    assert_raises(Buildkite::ConnectionError) { get }
  end
end
