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
* [nodeattr-server](https://github.com/openflighthpc/nodeattr-server) ~> 1.0

## Usage

`FlightFacade` provides a set of interfaces that implement look up methods to `nodes` and `groups`. The two main interfaces are:
* `FlightFacade::Facades::NodeFacade`
* `FlightFacade::Facades::GroupFacade`

These modules provide look up methods to the following models (respectively):
* `FlightFacade::Models::Node`
* `FlightFacade::Models::Group`

Each of the facade modules needs to be configure with a `facade_instance`. The `facade_instance` implements the look up methods and generates the models. By using the facades, the calling application can be decoupled from the data source.

### Configuring the Facades

Before the facades modules can be used, they must be configured with a `facade_instance`. Failure to do so will result in an error being raised. This section will go through each of the implementations and how to configure them.

The `facade_instances` must be set on each of the facade modules as follows:

```
FlightFacade::Facades::NodeFacade.facade_instance = <instance-of-node-facade>
FlightFacade::Facades::GroupFacade.facade_instance = <instance-of-group-facade>
```

#### Node Facade: Standalone

The primary implementation for the `nodes` is `FlightFacade::Facades::NodeFacade::Standalone` which requires a static hash of node data. It is initialised by:

```
FlightFacade::Facades::NodeFacade::Standalone.new(<node-data-hash>)
```

The hash should be in the following format:

```
{
  node1: {
    key1: 'value1',
    key2: 'value2',
  },
  node2: {
    ranks: ['overridden1', 'overridden2'],
    key1: 'value1'
  },
  <node-name>: {
    <key>: <value>,
    ...
  },
  ...
}
```

As the hash is static, it can not be changed once the facade has been initialized. This means any changes to the node data will likely require the application to be rebooted (depending on implementation).

#### Node Facade: Upstream

The `nodes` may also be integrated with an upstream `nodeattr-server` by using `FlightFacade::Facades::NodeFacade::Upstream`. This the nodes to be dynamically created and modified through the [nodeattr client](https://github.com/openflighthpc/nodeattr-client). All the facade methods make a single request each time they are called. This means the application does not need to be restarted after a node is modified.

The upstream `params` attribute for each `node` is used as a substitute to the parameters keys set in standalone mode.

The facade must be initialized with the `url`, access token, and cluster name:
**NOTE**: The facade should be given a `user` token as it does not modify the upstream resources.

```
conn = FlightFacade::Records.build_connection(<nodeattr-url>, <access-token>)
FlightFacade::Facades::NodeFacade::Upstream.new(connection: conn, cluster: <cluster-name>)
```

#### Group Facade: Exploding

The `primary` facade for `groups` is `FlightFacade::Facades::GroupFacade::Exploding`. This provides basic `group` name expansion into a list of `nodes`. It does not require any specific configuration and will delegate to `FlightFacade::Facades::NodeFacade` for the `node` data:

```
FlightFacade::Facade::GroupFacade::Exploding.new
```

The name expansion supports both comma separated lists and range expansions. The indices of a range expansion can be padded with zeros by including them as trailing characters in the name:

```
# Expanding a comma separated list
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node1,slave1,gpu1')
=> ['node1', 'slave1', 'gpu1']

# Expanding a range expression
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node[0-10]')
=> ['node0', 'node1', 'node2', ..., 'node9', 'node10']

# Expanding a range expression with padding
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node00[0-1000]')
=> ['node000', 'node001', ..., 'node010', 'node011', ..., 'node100', 'node101', ..., 'node999', 'node1000']

# Expanding a range expression with higher digit padding
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node0[10-100]')
=> ['node010', 'node011', ..., 'node099', 'node100']

# Incorrectly padding a range expression (padding within the brackets is ignored)
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node[001-100]')
=> ['node1', 'node2', ..., 'node99', 'node100']

# Combining range expressions with a comma seperated list
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node[1-5],node0[7-8],node10')
=> ['node1', 'node2', 'node3', 'node4', 'node5', 'node07', 'node08', 'node10']

# Removes duplicates
FlightFacade::Facades::GroupFacade::Exploding.expand_names('node[1-2],node1')
=> ['node1', 'node2']
```

#### Group Facade: Upstream

The `groups` may also be integrated with an upstream `nodeattr-server` by using `FlightFacade::Facades::GroupFacade::Upstream`. It is both dynamic and initialized in the same manner as the `node` version:

```
conn = FlightFacade::Records.build_connection(<nodeattr-url>, <access-token>)
FlightFacade::Facades::GroupFacade::Upstream.new(connection: conn, cluster: <cluster-name>)
```

To cut down on requests to the remote server, the `groups` may side load the `node` data within the same request. This means the group upstream mode must be used in conjunction with the node upstream mode. Failure to do this will lead to inconsistencies between the `NodeFacade` and `GroupFacade`.

### NOTES: FlightFacade::Models::Node

Each of the `NodeFacade` implementations will poll for a `node` based on its `name` and return an associated set of "parameters". The "parameters" are key value pairs and are used to provide both the regular `params` and special keys to the `FlightFacade::Models::Node`.

The `ranks` are a special key within `params` and is used to generate the property of the same name on `Flight::Models::Node`. The `params` are not modified by this translation and therefore should not match the model property. The "parameter ranks" is appended with the "default" rank before any duplicates are removed:

```
# If the ranks is not set
node = FlightFacade::Facades::NodeFacade.find_by_name ...
node.params[:ranks] # => nil
node.ranks          # => ['default']

# If the ranks is set to a value
node = FlightFacade::Facades::NodeFacade.find_by_name ...
node.params[:ranks] # => 'demo-rank'
node.ranks          # => ['demo-rank', 'default']

# If the ranks is set to an array
node = FlightFacade::Facades::NodeFacade.find_by_name ...
node.params[:ranks] # => ['rank1', 'rank2']
node.ranks          # => ['rank1', 'rank2', 'default']

# If there are duplicate ranks
node = FlightFacade::Facades::NodeFacade.find_by_name ...
node.params[:ranks] # => ['dup', 'other', 'dup']
node.ranks          # => ['dup', 'other', 'default']

# Incorrect use of the default rank
# NOTE: Any feature that relies on "ranks" will implement a default. Therefore any further ranks are redundant
node = FlightFacade::Facades::NodeFacade.find_by_name ...
node.params[:ranks] # => ['default', 'redundant']
node.ranks          # => ['default', 'redundant']
```

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
