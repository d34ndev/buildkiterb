module Buildkite
  class Emoji < Object

    class << self

      def list(org: Buildkite.config.org, **params)
        Collection.from_request("organizations/#{org}/emojis", type: Emoji, params: params)
      end

    end

  end
end
