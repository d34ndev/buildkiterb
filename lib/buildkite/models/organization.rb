module Buildkite
  class Organization < Object

    class << self

      def list(**params)
        Collection.from_request("organizations", type: Organization, params: params)
      end

      def retrieve(slug:)
        response = Client.get_request("organizations/#{slug}")
        Organization.new(response.body)
      end

    end

  end
end
