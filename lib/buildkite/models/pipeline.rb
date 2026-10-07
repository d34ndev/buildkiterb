module Buildkite
  class Pipeline < Object

    class << self

      def list(org: Buildkite.config.org, **params)
        Collection.from_request("organizations/#{org}/pipelines", type: Pipeline, params: params)
      end

      def retrieve(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline)
        response = Client.get_request("organizations/#{org}/pipelines/#{pipeline}")
        Pipeline.new response.body
      end

      def create(org: Buildkite.config.org, name:, repository:, configuration:, **args)
        data = {name: name, repository: repository, configuration: configuration}
        response = Client.post_request("organizations/#{org}/pipelines", body: data.merge(args))
        Pipeline.new response.body
      end

      def update(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, **args)
        response = Client.patch_request("organizations/#{org}/pipelines/#{pipeline}", body: args)
        Pipeline.new response.body
      end

      def archive(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline)
        response = Client.post_request("organizations/#{org}/pipelines/#{pipeline}/archive", body: {})
        Pipeline.new response.body
      end

      def unarchive(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline)
        response = Client.post_request("organizations/#{org}/pipelines/#{pipeline}/unarchive", body: {})
        Pipeline.new response.body
      end

      def delete(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline)
        Client.delete_request("organizations/#{org}/pipelines/#{pipeline}")
      end

      def webhook(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline)
        Client.post_request("organizations/#{org}/pipelines/#{pipeline}/webhook", body: {})
      end

    end

  end
end
