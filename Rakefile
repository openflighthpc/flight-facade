#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of FlightFacade.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# FlightFacade is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with FlightFacade. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on FlightFacade , please visit:
# https://github.com/openflighthpc/flight_facade
#===============================================================================

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :'nodeattr:drop', [:url, :token] do |_, args|
  require 'flight_facade'
  conn = FlightFacade::BaseRecord.build_connection(args[:url], args[:token])

  cluster = FlightFacade::ClustersRecord.fetch(connection: conn,
                                               url_opts: { id: '.test' },
                                               includes: ['nodes', 'groups'])

  cluster.groups.each(&:delete)
  cluster.nodes.each(&:delete)
  cluster.delete
end

task :'nodeattr:setup', [:url, :token] do |_, args|
  require 'flight_facade'
  require_relative 'spec/fixtures/demo_cluster.rb'

  conn = FlightFacade::BaseRecord.build_connection(args[:url], args[:token])

  cluster = FlightFacade::ClustersRecord.create(connection: conn, name: 'test')

  FlightFacade::DemoCluster.nodes_data.each do |name, attr|
    FlightFacade::NodesRecord.create(connection: conn,
                                     name: name,
                                     cluster: cluster,
                                     level_params: attr[:params] || {})
  end

  FlightFacade::DemoCluster.groups_data.each do |name, attr|
    nodes_data = (attr[:nodes] || []).map do |n|
      FlightFacade::NodesRecord.new(id: "test.#{n}", connection: nil)
    end
    FlightFacade::GroupsRecord.create(connection: conn,
                                      name: name,
                                      cluster: cluster,
                                      nodes: nodes_data)
  end
end

task :console do
  require 'flight_facade'
  require 'pry'
  Pry.start
end

