module Buildkite
  class Agent < Object

    class << self

      def list(org: Buildkite.config.org, **params)
        Collection.from_request("organizations/#{org}/agents", type: Agent, params: params)
      end

      def retrieve(org: Buildkite.config.org, id:)
        response = Client.get_request("organizations/#{org}/agents/#{id}")
        Agent.new response.body
      end

      def stop(org: Buildkite.config.org, id:, **args)
        Client.put_request("organizations/#{org}/agents/#{id}/stop", body: args)
      end

    end

  end
end
