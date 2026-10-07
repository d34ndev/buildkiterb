require "faraday"

require_relative "buildkite/version"
require_relative "buildkite/error"

module Buildkite

  autoload :Configuration, "buildkite/configuration"
  autoload :Client, "buildkite/client"
  autoload :Collection, "buildkite/collection"
  autoload :Object, "buildkite/object"

  class << self
    attr_writer :config
  end

  def self.configure
    yield(config) if block_given?
  end

  def self.config
    @config ||= Buildkite::Configuration.new
  end

  autoload :AccessToken, "buildkite/models/access_token"
  autoload :Organization, "buildkite/models/organization"
  autoload :Pipeline, "buildkite/models/pipeline"
  autoload :Build, "buildkite/models/build"
  autoload :Job, "buildkite/models/job"
  autoload :JobLog, "buildkite/models/job_log"
  autoload :JobEnv, "buildkite/models/job_env"
  autoload :Agent, "buildkite/models/agent"
  autoload :Cluster, "buildkite/models/cluster"
  autoload :ClusterQueue, "buildkite/models/cluster_queue"
  autoload :ClusterToken, "buildkite/models/cluster_token"
  autoload :Annotation, "buildkite/models/annotation"
  autoload :Artifact, "buildkite/models/artifact"
  autoload :ArtifactDownload, "buildkite/models/artifact_download"
  autoload :Emoji, "buildkite/models/emoji"
  autoload :User, "buildkite/models/user"

end
