require "test_helper"

# Checks the HTTP method and body sent for endpoints, using stubs rather than cassettes
class RequestShapeTest < Minitest::Test

  def setup
    @config = Buildkite.config
    @original_adapter = @config.adapter
    @stubs = Faraday::Adapter::Test::Stubs.new
    @config.adapter = [:test, @stubs]
    VCR.turn_off!
  end

  def teardown
    VCR.turn_on!
    @config.adapter = @original_adapter
    Buildkite::Client.reset!
  end

  def json(body = {}, status: 200, headers: {})
    [status, {"Content-Type" => "application/json"}.merge(headers), body.to_json]
  end

  def test_queue_pause_sends_dispatch_paused_note
    sent = nil
    @stubs.post("/v2/organizations/o/clusters/c/queues/q/pause_dispatch") { |env| sent = JSON.parse(env.body); json }

    Buildkite::ClusterQueue.pause(org: "o", cluster: "c", id: "q", note: "Investigating")

    assert_equal({"dispatch_paused_note" => "Investigating"}, sent)
  end

  def test_cluster_update_uses_put
    sent = nil
    @stubs.put("/v2/organizations/o/clusters/c") { |env| sent = JSON.parse(env.body); json }

    Buildkite::Cluster.update(org: "o", id: "c", description: "New")

    assert_equal({"description" => "New"}, sent)
  end

  def test_queue_update_uses_put
    @stubs.put("/v2/organizations/o/clusters/c/queues/q") { json }
    Buildkite::ClusterQueue.update(org: "o", cluster: "c", id: "q", description: "New")
    @stubs.verify_stubbed_calls
  end

  def test_token_update_uses_put
    @stubs.put("/v2/organizations/o/clusters/c/tokens/t") { json }
    Buildkite::ClusterToken.update(org: "o", cluster: "c", id: "t", description: "New")
    @stubs.verify_stubbed_calls
  end

  def test_artifact_download_reads_url_from_body
    @stubs.get("/v2/organizations/o/pipelines/p/builds/1/jobs/j/artifacts/a/download") do
      json({url: "https://example.com/body"}, status: 302, headers: {"Location" => "https://example.com/header"})
    end

    download = Buildkite::Artifact.download(org: "o", pipeline: "p", build: 1, job: "j", id: "a")

    assert_equal "https://example.com/body", download.url
  end

  def test_artifact_download_falls_back_to_location_header
    @stubs.get("/v2/organizations/o/pipelines/p/builds/1/jobs/j/artifacts/a/download") do
      [302, {"Location" => "https://example.com/header"}, ""]
    end

    download = Buildkite::Artifact.download(org: "o", pipeline: "p", build: 1, job: "j", id: "a")

    assert_equal "https://example.com/header", download.url
  end
end
