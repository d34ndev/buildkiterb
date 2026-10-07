module Buildkite
  class Cluster < Object

    class << self

      def list(org: Buildkite.config.org, **params)
        Collection.from_request("organizations/#{org}/clusters", type: Cluster, params: params)
      end

      def retrieve(org: Buildkite.config.org, id:)
        response = Client.get_request("organizations/#{org}/clusters/#{id}")
        Cluster.new response.body
      end

      def create(org: Buildkite.config.org, name:, **args)
        data = {name: name}
        response = Client.post_request("organizations/#{org}/clusters", body: data.merge(args))
        Cluster.new response.body
      end

      def update(org: Buildkite.config.org, id:, **args)
        response = Client.patch_request("organizations/#{org}/clusters/#{id}", body: args)
        Cluster.new response.body
      end

      def delete(org: Buildkite.config.org, id:)
        Client.delete_request("organizations/#{org}/clusters/#{id}")
      end

    end

  end
end
