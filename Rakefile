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

  cluster.nodes.each(&:delete)
  cluster.groups.each(&:delete)
  cluster.delete
end

task :'nodeattr:setup', [:url, :token] do |_, args|
  require 'flight_facade'
  require_relative 'spec/fixtures/demo_cluster.rb'

  conn = FlightFacade::BaseRecord.build_connection(args[:url], args[:token])

  cluster = FlightFacade::ClustersRecord.create(connection: conn, name: 'test')

  FlightFacade::DemoCluster.nodes_data.each do |name, _|
    FlightFacade::NodesRecord.create(connection: conn, name: name, cluster: cluster)
  end
end

