require "test_helper"

class ObjectTest < Minitest::Test
  def test_creating_object_from_hash
    assert_equal "bar", Buildkite::Object.new(foo: "bar").foo
  end

  def test_nested_hash
    assert_equal "foobar", Buildkite::Object.new(foo: {bar: {baz: "foobar"}}).foo.bar.baz
  end

  def test_nested_number
    assert_equal 1, Buildkite::Object.new(foo: {bar: 1}).foo.bar
  end

  def test_array
    object = Buildkite::Object.new(foo: [{bar: :baz}])
    assert_equal Buildkite::Object, object.foo.first.class
    assert_equal :baz, object.foo.first.bar
  end

  def test_string_and_symbol_access
    object = Buildkite::Object.new("id" => "1")
    assert_equal "1", object[:id]
    assert_equal "1", object["id"]
    assert object.key?(:id)
    refute object.key?(:missing)
  end

  def test_missing_attribute_returns_nil
    assert_nil Buildkite::Object.new(foo: "bar").missing
  end

  def test_attributes_named_like_object_methods
    object = Buildkite::Object.new(env: {"BUILDKITE_BRANCH" => "main"})
    assert_equal "main", object.env.BUILDKITE_BRANCH
    assert_equal "main", object.env[:BUILDKITE_BRANCH]
  end

  def test_to_h_converts_nested_objects
    object = Buildkite::Object.new("id" => "1", "creator" => {"name" => "Dean"}, "jobs" => [{"a" => 1}, 2])
    assert_equal({id: "1", creator: {name: "Dean"}, jobs: [{a: 1}, 2]}, object.to_h)
  end

  def test_to_json
    assert_equal '{"id":"1"}', Buildkite::Object.new(id: "1").to_json
  end

  def test_equality
    assert_equal Buildkite::Object.new(a: {b: 1}), Buildkite::Object.new("a" => {"b" => 1})
  end

  def test_assignment
    object = Buildkite::Object.new
    object.foo = {bar: 1}
    assert_equal 1, object.foo.bar
  end
end
