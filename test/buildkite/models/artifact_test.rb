require "test_helper"

class ArtifactTest < Minitest::Test

  def test_artifact_list_build
    artifacts = Buildkite::Artifact.list(pipeline: "starter-buildkite-pipeline", build: 8)

    assert_equal Buildkite::Collection, artifacts.class
    assert_equal Buildkite::Artifact, artifacts.data.first.class
    assert_equal "README.md", artifacts.data.first.filename
  end

  def test_artifact_list_job
    artifacts = Buildkite::Artifact.list(pipeline: "starter-buildkite-pipeline", build: 8, job: "018a1486-a2d6-4d80-8204-b6cd3a1a18a5")

    assert_equal Buildkite::Collection, artifacts.class
    assert_equal Buildkite::Artifact, artifacts.data.first.class
    assert_equal "README.md", artifacts.data.first.filename
  end

  def test_artifact_retrieve
    artifact = Buildkite::Artifact.retrieve(pipeline: "starter-buildkite-pipeline", build: 8, job: "018a1486-a2d6-4d80-8204-b6cd3a1a18a5", id: "018a1486-bd2f-4e59-9211-2314043fca05")

    assert_equal Buildkite::Artifact, artifact.class
    assert_equal "README.md", artifact.filename
  end

  def test_artifact_download
    artifact = Buildkite::Artifact.download(pipeline: "starter-buildkite-pipeline", build: 8, job: "018a1486-a2d6-4d80-8204-b6cd3a1a18a5", id: "018a1486-bd2f-4e59-9211-2314043fca05")

    assert_equal Buildkite::ArtifactDownload, artifact.class
    assert_match (/buildkiteartifacts.com/), artifact.url
  end

  def test_artifact_delete
    artifact = Buildkite::Artifact.delete(pipeline: "starter-buildkite-pipeline", build: 8, job: "018a1486-a2d6-4d80-8204-b6cd3a1a18a5", id: "018a1486-bd2f-4e59-9211-2314043fca05")

    assert artifact
  end

end
