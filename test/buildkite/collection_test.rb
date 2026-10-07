require "test_helper"

class CollectionTest < Minitest::Test

  LINK = '<https://api.buildkite.com/v2/builds?page=3&per_page=2>; rel="next", ' \
         '<https://api.buildkite.com/v2/builds?page=1&per_page=2>; rel="prev", ' \
         '<https://api.buildkite.com/v2/builds?page=9&per_page=2>; rel="last"'

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

  def page(items, link: nil)
    headers = {"Content-Type" => "application/json"}
    headers["Link"] = link if link
    [200, headers, items.map { |id| {id: id} }.to_json]
  end

  def test_page_from_link
    assert_equal 3, Buildkite::Collection.page_from_link(LINK, "next")
    assert_equal 1, Buildkite::Collection.page_from_link(LINK, "prev")
    assert_equal 9, Buildkite::Collection.page_from_link(LINK, "last")
    assert_nil Buildkite::Collection.page_from_link(LINK, "first")
    assert_nil Buildkite::Collection.page_from_link(nil, "next")
  end

  def test_single_page
    @stubs.get("/v2/builds") { page([1, 2]) }

    builds = Buildkite::Build.list

    assert_equal [1, 2], builds.map(&:id)
    assert_equal 2, builds.total
    refute builds.next_page?
    assert_nil builds.next_page
  end

  def test_params_are_sent
    seen = nil
    @stubs.get("/v2/organizations/acme/builds") { |env| seen = env.params; page([1]) }

    Buildkite::Build.list(org: "acme", branch: "main", state: "failed", per_page: 100)

    assert_equal({"branch" => "main", "state" => "failed", "per_page" => "100"}, seen)
  end

  def test_next_page_keeps_params
    seen = []
    @stubs.get("/v2/builds") do |env|
      seen << env.params
      env.params["page"] ? page([3, 4]) : page([1, 2], link: '<https://api.buildkite.com/v2/builds?page=2>; rel="next"')
    end

    builds = Buildkite::Build.list(branch: "main")

    assert builds.next_page?
    assert_equal 2, builds.next_page_number
    assert_equal [3, 4], builds.next_page.map(&:id)
    assert_equal [{"branch" => "main"}, {"branch" => "main", "page" => "2"}], seen
  end

  def test_auto_paginate_walks_every_page
    pages = {
      nil => page([1, 2], link: '<https://api.buildkite.com/v2/builds?page=2>; rel="next"'),
      "2" => page([3, 4], link: '<https://api.buildkite.com/v2/builds?page=3>; rel="next"'),
      "3" => page([5])
    }
    @stubs.get("/v2/builds") { |env| pages.fetch(env.params["page"]) }

    assert_equal [1, 2, 3, 4, 5], Buildkite::Build.list.auto_paginate.map(&:id).to_a
  end

  def test_auto_paginate_is_lazy
    requested = []
    @stubs.get("/v2/builds") do |env|
      requested << env.params["page"]
      page([1, 2], link: "<https://api.buildkite.com/v2/builds?page=#{env.params["page"].to_i + 1}>; rel=\"next\"")
    end

    assert_equal [1, 2, 1], Buildkite::Build.list.auto_paginate.first(3).map(&:id)
    assert_equal [nil, "1"], requested
  end

  def test_each_page
    @stubs.get("/v2/builds") { |env| env.params["page"] ? page([2]) : page([1], link: '<x?page=2>; rel="next"') }

    assert_equal [[1], [2]], Buildkite::Build.list.each_page.map { |p| p.map(&:id) }
  end

  def test_artifact_list_with_job_and_params
    paths = []
    @stubs.get("/v2/organizations/o/pipelines/p/builds/1/artifacts") { paths << :build; page([]) }
    @stubs.get("/v2/organizations/o/pipelines/p/builds/1/jobs/j/artifacts") { paths << :job; page([]) }

    Buildkite::Artifact.list(org: "o", pipeline: "p", build: 1, per_page: 5)
    Buildkite::Artifact.list(org: "o", pipeline: "p", build: 1, job: "j")

    assert_equal [:build, :job], paths
  end
end
