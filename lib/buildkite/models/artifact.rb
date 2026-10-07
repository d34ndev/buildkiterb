module Buildkite
  class Artifact < Object

    class << self

      def list(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, build:, job: nil, **params)
        path = "organizations/#{org}/pipelines/#{pipeline}/builds/#{build}"
        path += "/jobs/#{job}" if job

        Collection.from_request("#{path}/artifacts", type: Artifact, params: params)
      end

      def retrieve(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, build:, job:, id:)
        response = Client.get_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{build}/jobs/#{job}/artifacts/#{id}")
        Artifact.new response.body
      end

      def download(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, build:, job:, id:)
        response = Client.get_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{build}/jobs/#{job}/artifacts/#{id}/download")
        ArtifactDownload.new response.body
      end

      def delete(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, build:, job:, id:)
        Client.delete_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{build}/jobs/#{job}/artifacts/#{id}")
      end

    end

  end
end
