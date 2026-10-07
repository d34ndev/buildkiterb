# BuildkiteRB

BuiltkiteRB is a Ruby library for the Buildkite API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "buildkiterb"
```

## Usage

### Set Client Details

Firstly you'll need to create an API Token on [Buildkite](https://buildkite.com/user/api-access-tokens)
and then configure it like below.

Buildkite tokens are created for a single organization now, so I recommend setting the `org` the same way,
to tidy up your code.

You can optionally set a pipeline too.

```ruby
Buildkite.configure do |config|
  config.token    = ENV["BUILDKITE_TOKEN"]
  config.org      = ENV["BUILDKITE_ORG"]
  config.pipeline = ENV["BUILDKITE_PIPELINE"]
end

```

Other settings are optional:

```ruby
Buildkite.configure do |config|
  config.timeout        = 30 # seconds to wait for a response
  config.open_timeout   = 10 # seconds to wait for the connection to open
  config.max_retries    = 2  # times to retry a rate limited request, 0 to disable
  config.max_retry_wait = 60 # raise instead of waiting longer than this many seconds
end
```

### Pagination and filtering

Buildkite returns 30 results per page (100 at most). Every `list` method returns a `Buildkite::Collection`,
which is `Enumerable` over the items on that page. Pass any filters the API supports, including `page` and `per_page`.

```ruby
builds = Buildkite::Build.list(org: "org-slug", branch: "main", state: "failed", per_page: 100)
builds.each { |build| puts build.number }

# Fetch the next page
builds.next_page? #=> true
builds.next_page  #=> Buildkite::Collection or nil on the last page

# Lazily walk every page, only fetching the pages you use
Buildkite::Build.list(per_page: 100).auto_paginate.first(250)
Buildkite::Pipeline.list.auto_paginate.map(&:slug)

# Or page by page
Buildkite::Build.list.each_page { |page| puts page.total }
```

`total` is the number of items on the page, as Buildkite doesn't report an overall total.

### Responses

Responses are `Buildkite::Object`s. Read attributes with dot notation or like a hash. Missing attributes are `nil`.

```ruby
build = Buildkite::Build.retrieve(pipeline: "pipeline-slug", number: 123)
build.state
build[:state]
build["creator"]["name"]
build.creator.name
build.to_h
```

### Errors

Every error is a `Buildkite::Error`, so `rescue Buildkite::Error` catches them all. It has `status`, `body`
and `response`. API errors are one of the subclasses below.

| Status | Error |
| --- | --- |
| 400 | `Buildkite::BadRequestError` |
| 401 | `Buildkite::AuthenticationError` |
| 403 | `Buildkite::ForbiddenError` |
| 404 | `Buildkite::NotFoundError` |
| 409 | `Buildkite::ConflictError` |
| 422 | `Buildkite::UnprocessableEntityError` |
| 429 | `Buildkite::RateLimitError` (after retries are used up) |
| 5xx | `Buildkite::ServerError` |

Timeouts and connection failures raise `Buildkite::ConnectionError`.

```ruby
begin
  Buildkite::Build.retrieve(pipeline: "pipeline-slug", number: 999)
rescue Buildkite::NotFoundError => e
  e.status #=> 404
  e.body   #=> {"message" => "No build found"}
end
```

### Access Token

```ruby
# Get details of the current token
Buildkite::AccessToken.retrieve

# Revoke the current token
Buildkite::AccessToken.revoke
```

### Organizations

```ruby
# Retrieves an organization
Buildkite::Organization.retrieve slug: "my-org-slug"
```

### Pipelines

```ruby
# List all pipelines for an org
Buildkite::Pipeline.list
#=> #<Buildkite::Collection...

# Get a pipeline
Buildkite::Pipeline.retrieve pipeline: "my pipeline"

# Create a Pipeline. View the 2 docs links for the correct params
# Docs: https://buildkite.com/docs/apis/rest-api/pipelines#create-a-yaml-pipeline
# Docs: https://buildkite.com/docs/apis/rest-api/pipelines#create-a-visual-step-pipeline
Buildkite::Pipeline.create name: "my pipeline", repository: "git@github.com:user/repo.git", configuration: {}

# Update a pipeline
# Docs: https://buildkite.com/docs/apis/rest-api/pipelines#update-a-pipeline
Buildkite::Pipeline.update pipeline: "my-pipeline", {}

# Archive a pipeline
Buildkite::Pipeline.archive pipeline: "my-pipeline"

# Unarchive a pipeline
Buildkite::Pipeline.unarchive pipeline: "my-pipeline"

# Delete a pipeline
Buildkite::Pipeline.delete pipeline: "my-pipeline"

# Setup automatic webhooks
# Returns 422 if not supported or cannot be done
Buildkite::Pipeline.webhook pipeline: "my-pipeline"
```

### Builds

```ruby
# List all builds across every organization your token can see
Buildkite::Build.list

# Filter builds
Buildkite::Build.list org: "org-slug", branch: "main", state: "passed"

# List all builds for an org
Buildkite::Build.list org: "org-slug"

# List all builds for a pipeline
Buildkite::Build.list org: "org-slug", pipeline: "pipeline-slug"

# Get a build
# The Build Number is used, not the ID
Buildkite::Build.retrieve pipeline: "pipeline-slug", number: 123

# Create a Build
# Docs: https://buildkite.com/docs/apis/rest-api/builds#create-a-build
Buildkite::Build.create pipeline: "pipeline-slug", commit: "abc123", branch: "master"

# Cancel a build
Buildkite::Build.cancel pipeline: "pipeline-slug", number: 123

# Rebuild a build
Buildkite::Build.rebuild pipeline: "pipeline-slug", number: 123
```

### Agents

```ruby
# List all agents for an org
Buildkite::Agent.list

# Get an agent
Buildkite::Agent.retrieve id: "abc123"

# Stop an agent
# To force an agent to stop, add `force: true`
Buildkite::Agent.stop id: "abc123"
```

### Clusters

```ruby
# List all clusters for an org
Buildkite::Cluster.list

# Get a cluster
Buildkite::Cluster.retrieve id: "abc123"

# Create a cluster
Buildkite::Cluster.create name: "Open Source"

# Update a cluster
Buildkite::Cluster.update id: "abc123", description: "A cluster for our Open Source projects"

# Delete a cluster
Buildkite::Cluster.delete id: "abc123"
```

### Cluster Queues

```ruby
# List all queues for a cluster
Buildkite::ClusterQueue.list cluster: "abc123",

# Get a cluster queue
Buildkite::ClusterQueue.retrieve cluster: "abc123", id: "abc123"

# Create a cluster queue
Buildkite::ClusterQueue.create cluster: "abc123", key: "arm64"

# Update a cluster queue
Buildkite::ClusterQueue.update cluster: "abc123", id: "abc123", description: "For ARM64 builds"

# Pause a cluster queue
Buildkite::ClusterQueue.pause cluster: "abc123", id: "abc123", note: "For maintenance"

# Unpause a cluster queue
Buildkite::ClusterQueue.unpause cluster: "abc123", id: "abc123"

# Delete a cluster queue
Buildkite::ClusterQueue.delete cluster: "abc123", id: "abc123"
```

### Cluster Tokens

```ruby
# List all tokens for a cluster
Buildkite::ClusterToken.list cluster: "abc123",

# Get a cluster token
Buildkite::ClusterToken.retrieve cluster: "abc123", id: "abc123"

# Create a cluster token
Buildkite::ClusterToken.create cluster: "abc123", description: "Windows Agents"

# Update a cluster token
Buildkite::ClusterToken.update cluster: "abc123", id: "abc123", allowed_ip_addresses: "1.1.1.1"

# Delete a cluster token
Buildkite::ClusterToken.delete cluster: "abc123", id: "abc123"
```


### Jobs

```ruby
# Retry a job
Buildkite::Job.retry pipeline: "pipeline-slug", number: 123, job: "abc123"

# Unblock a job
# Docs: https://buildkite.com/docs/apis/rest-api/jobs#unblock-a-job
Buildkite::Job.unblock pipeline: "pipeline-slug", number: 123, job: "abc123", {}

# Get a job's logs
Buildkite::Job.log pipeline: "pipeline-slug", number: 123, job: "abc123"

# Delete a job's log
Buildkite::Job.delete_log pipeline: "pipeline-slug", number: 123, job: "abc123"

# Get a job's environment variables
Buildkite::Job.env pipeline: "pipeline-slug", number: 123, job: "abc123"
```

### Annotations

```ruby
# List annotations for a build
Buildkite::Annotation.list pipeline: "pipeline-slug", number: 123
```

### Artifacts

```ruby
# List artifacts for a build
Buildkite::Artifact.list pipeline: "pipeline-slug", number: 123

# List artifacts for a build job
Buildkite::Artifact.list pipeline: "pipeline-slug", number: 123, job: "abc123"

# Get an artifact
Buildkite::Artifact.retrieve pipeline: "pipeline-slug", number: 123, job: "abc123", id: "123abc"

# Download an artifact
Buildkite::Artifact.download pipeline: "pipeline-slug", number: 123, job: "abc123", id: "123abc"

# Delete an artifact
Buildkite::Artifact.delete pipeline: "pipeline-slug", number: 123, job: "abc123", id: "123abc"
```

### Emojis

```ruby
# List emojis for an organization
Buildkite::Emoji.list
```

### User

```ruby
# Get the current user
Buildkite::User.retrieve
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/d34ndev/buildkiterb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
