# FlightFacade

Provides a standardised set of interfaces to cluster concepts. These interfaces can be either configured to work in a standalone mode OR integrate with other services.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flight_facade'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flight_facade

## Compatibility

`FlightFacade` integrates with external services via network requests and is compatible with:
* `nodeattr-server` ~> 1.0

## Usage

TODO: Write usage instructions here

## Development

This gem has been designed to integrate with [nodeattr-server](https://github.com/openflighthpc/nodeattr-server) as a possible source of `node`/`group` data. This causes issues in development as the external service isn't necessarily available.

To help elevate this problem, the `VCR` library is used to record all `http` interactions so they can be played back in `rspec`. This allows the spec to be ran without setting up the external service.

```
# Run the tests with the pre recorded HTTP requests
rspec
```

### Setting Up Demo Cluster for RSpec

Using `VCR` is a chicken and egg scenario when adding additional requests as the external service is required for the initial request. Therefore a demo cluster needs to be setup for this purpose. There are also times where the requests need to be refreshed/ removed, making reproducibility critical.

Initially a blank `nodeattr-server` needs to be created by following the instructions [here](https://github.com/openflighthpc/nodeattr-server#manual-installation). The server must be running on `localhost` port `6301`.

Then a `JWT` authorization token with `admin` level access needs to be generated ([generate jwt](https://github.com/openflighthpc/nodeattr-server#authentication)). The `nodeattr-server` maybe run in either the `development` or `production` environment with a matching token. The token needs to be exported into the environment as `SPEC_JWT`. The remainder of the guide will assume this has been done:

```
export SPEC_JWT=<generated-admin-jwt>
```

Next the [demo cluster](spec/fixtures/demo_cluster.rb) needs to be added to the server. As the `demo-cluster` is checked into this repo, it provides a reproducible setup that can be used to generate the `VCR` cassette. The following rake task is used to add the cluster to the service:

```
rake nodeattr:setup[http://localhost:6301,$SPEC_JWT]
```

It is not possible to re-add the demo cluster once it already exists. Instead it must be dropped from the service and then recreated. The following rake task will drop the demo cluster (proceed with caution).

```
rake nodeattr:drop[http://localhost:6301,$SPEC_JWT]
```

### Making new requests

By default `VCR` will error if a requests is made which it does not recognise. This is to prevent the spec being tied to an external service during testing. However it does prevent new specs from being added if they need to make an additional request.

To allow additional requests, `new_episodes` need to be enabled. Please refer to the [spec helper](spec/spec_helper.rb) on how to do this. In short, the `@vcr_record_mode` line needs to be uncommented. This change must not be committed into the repo as this will permanently allow new requests to be made.

### IMPORTANT: Modifying the Demo Cluster

**Under no circumstances should the demo cluster be manually modified**. This will cause the [VCR cassette](spec/fixtures/vcr_cassettes/default.yml) to get out of sync with the [demo cluster setup](spec/fixtures/demo_cluster.rb). This will lead to all sorts of issues concerning reproducibility and will almost certainly (eventually) break the test suite.

Instead the modifications need to be made to the `demo-cluster` fixture. By making the change, the old `VCR` cassettes is now stale and needs to be deleted entirely. Then it can be recreated by re-running the test suite will the `new_episodes` flag enabled.

It is critical this process is done within a single commit WITHOUT changes to the test suite. This is to ensure the spec goes from a known valid state to another valid state. Please review the diff on the cassette to ensure no additional requests have been made, as this indicates something unexpected has happened (changes to the ID/timestamps are to be expected). 

```
set -e

# Step 1: Ensure the repository is clean
git diff --exit-code

# Step 2: Make the change to the demo cluster fixture
# NOTE: You may use emacs/ed/nano/<insert-favourite-editor-here> if you wish
vim spec/fixtures/demo_cluster.rb

# Step 3: Drop the existing external cluster configuration
rake nodeattr:drop[http://localhost:6301,$SPEC_JWT]

# Step 4: Add the new external cluster configuration
rake nodeattr:setup[http://localhost:6301,$SPEC_JWT]

# Step 5: Remove the stale VCR cassettes
rm spec/fixtures/vcr/cassettes/*

# Step 6: Allow new_episodes to be added to the cassettes
sed -i 's/#\s@vcr_record_mode/@vcr_record_mode/' spec/spec_helper.rb

# Step 7: Regenerate the cassettes by re-running the test suite
rspec

# Step 8: Undo the change allowing new_episodes
# NOTE: Under no circumstances should this be committed into the repo
git checkout HEAD spec/spec_helper.rb

# Step 9: Ensure all the tests work with the new cassettes
rspec --order random

# Step 10: Review the changes and ensure no new requests have been made
# NOTE: The IDs and timestamps would have changed in addition to any resources
# modified in step 2
git diff

# Step 11: Commit all the changes
git commit -a
```

## Contributing

Fork the project. Make your feature addition or bug fix. Send a pull request. Bonus points for topic branches.

Read CONTRIBUTING.md for more details.

## Copyright and License
Eclipse Public License 2.0, see LICENSE.txt for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under the terms of the Eclipse Public License 2.0 which is available at https://www.eclipse.org/legal/epl-2.0, or alternative license terms made available by Alces Flight Ltd - please direct inquiries about licensing to licensing@alces-flight.com.

FlightFacade is distributed in the hope that it will be useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more details.
