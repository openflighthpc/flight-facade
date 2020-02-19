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

require 'hashie'

module FlightFacade
  module NodeFacade
    include HasFacade

    module Base
      # Query for a Node object by its name alone
      # @param name [String] the name of the node
      # @return [Node, nil] the node object or nil if it could not resolve the name
      def find_by_name(name)
        raise NotImplementedError
      end

      # Query for all the available nodes
      # It MAY not return the associated groups
      # @return [Array<Node>] the list of nodes
      def index_all
        raise NotImplementedError
      end
    end

    define_facade('Dummy')

    define_facade('Standalone', Hash) do
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess

      def initialize(*_)
        super
        delete('__meta__')
      end

      def find_by_name(input)
        name = input.to_s
        return nil unless key?(name)
        data = self[name].symbolize_keys
        ranks = data[:ranks] || []
        params = data.reject { |k, _| k == :ranks }
        Node.new(name: name, params: params, ranks: ranks)
      end

      def index_all
        keys.map { |k| find_by_name(k) }
      end
    end

    define_facade('Upstream', Hashie::Dash) do
      property :connection, requried: true
      property :cluster,    required: true

      def index_all
        NodesRecord.fetch_all(connection: connection, url: "/clusters/.#{cluster}/nodes")
                   .map do |node|
          Node.new(name: node.name, params: node.params)
        end
      end
    end
  end
end

