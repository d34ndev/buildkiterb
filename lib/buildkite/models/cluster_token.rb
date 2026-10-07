module Buildkite
  class ClusterToken < Object

    class << self

      def list(org: Buildkite.config.org, cluster:, **params)
        Collection.from_request("organizations/#{org}/clusters/#{cluster}/tokens", type: ClusterToken, params: params)
      end

      def retrieve(org: Buildkite.config.org, cluster:, id:)
        response = Client.get_request("organizations/#{org}/clusters/#{cluster}/tokens/#{id}")
        ClusterToken.new response.body
      end

      def create(org: Buildkite.config.org, cluster:, description:, **args)
        data = {description: description}
        response = Client.post_request("organizations/#{org}/clusters/#{cluster}/tokens", body: data.merge(args))
        ClusterToken.new response.body
      end

      def update(org: Buildkite.config.org, cluster:, id:, **args)
        response = Client.patch_request("organizations/#{org}/clusters/#{cluster}/tokens/#{id}", body: args)
        ClusterToken.new response.body
      end

      def delete(org: Buildkite.config.org, cluster:, id:)
        Client.delete_request("organizations/#{org}/clusters/#{cluster}/tokens/#{id}")
      end

    end

  end
end
