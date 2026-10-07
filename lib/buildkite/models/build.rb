module Buildkite
  class Build < Object

    class << self

      # With no org this lists builds across every organization the token can see. Pass
      # filters such as branch:, state:, creator: or created_from: as keyword arguments.
      def list(org: nil, pipeline: nil, **params)
        path = if org && pipeline
          "organizations/#{org}/pipelines/#{pipeline}/builds"
        elsif org
          "organizations/#{org}/builds"
        else
          "builds"
        end

        Collection.from_request(path, type: Build, params: params)
      end

      def retrieve(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, number:)
        response = Client.get_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{number}")
        Build.new response.body
      end

      def create(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, commit:, branch:, **args)
        data = {commit: commit, branch: branch}
        response = Client.post_request("organizations/#{org}/pipelines/#{pipeline}/builds", body: data.merge(args))
        Build.new response.body
      end

      def cancel(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, number:)
        response = Client.put_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{number}/cancel", body: {})
        Build.new response.body
      end

      def rebuild(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, number:)
        response = Client.put_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{number}/rebuild", body: {})
        Build.new response.body
      end

    end

  end
end
