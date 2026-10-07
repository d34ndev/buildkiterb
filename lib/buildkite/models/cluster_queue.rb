module Buildkite
  class ClusterQueue < Object

    class << self

      def list(org: Buildkite.config.org, cluster:, **params)
        Collection.from_request("organizations/#{org}/clusters/#{cluster}/queues", type: ClusterQueue, params: params)
      end

      def retrieve(org: Buildkite.config.org, cluster:, id:)
        response = Client.get_request("organizations/#{org}/clusters/#{cluster}/queues/#{id}")
        ClusterQueue.new response.body
      end

      def create(org: Buildkite.config.org, cluster:, key:, **args)
        data = {key: key}
        response = Client.post_request("organizations/#{org}/clusters/#{cluster}/queues", body: data.merge(args))
        ClusterQueue.new response.body
      end

      def update(org: Buildkite.config.org, cluster:, id:, **args)
        response = Client.put_request("organizations/#{org}/clusters/#{cluster}/queues/#{id}", body: args)
        ClusterQueue.new response.body
      end

      def pause(org: Buildkite.config.org, cluster:, id:, note: nil)
        response = Client.post_request("organizations/#{org}/clusters/#{cluster}/queues/#{id}/pause_dispatch", body: {dispatch_paused_note: note})
        ClusterQueue.new response.body
      end

      def resume(org: Buildkite.config.org, cluster:, id:)
        response = Client.post_request("organizations/#{org}/clusters/#{cluster}/queues/#{id}/resume_dispatch", body: {})
        ClusterQueue.new response.body
      end

      def delete(org: Buildkite.config.org, cluster:, id:)
        Client.delete_request("organizations/#{org}/clusters/#{cluster}/queues/#{id}")
      end

    end

  end
end
