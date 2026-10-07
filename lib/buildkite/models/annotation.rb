module Buildkite
  class Annotation < Object

    class << self

      def list(org: Buildkite.config.org, pipeline: Buildkite.config.pipeline, build:, **params)
        Collection.from_request("organizations/#{org}/pipelines/#{pipeline}/builds/#{build}/annotations", type: Annotation, params: params)
      end

    end

  end
end
