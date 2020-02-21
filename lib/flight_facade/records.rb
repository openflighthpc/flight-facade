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

require 'simple_jsonapi_client'
require 'faraday'
require 'faraday_middleware'

module FlightFacade
  module Records
    def self.build_connection(url, token)
      headers = {
        'Accept' => 'application/vnd.api+json',
        'Content-Type' => 'application/vnd.api+json',
        'Authorization' => "Bearer #{token}"
      }

      Faraday.new(url: url, headers: headers) do |conn|
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.adapter :net_http
      end
    end

    class BaseRecord < SimpleJSONAPIClient::Base
      def self.inherited(klass)
        type = klass.name.split('::').last.chomp('Record').downcase
        klass.const_set('COLLECTION_URL', "/#{type}")
        klass.const_set('INDIVIDUAL_URL', "/#{type}/%{id}")
        klass.const_set('TYPE', type)
      end
    end

    class NodesRecord < BaseRecord
      attributes :name, :params, :level_params

      has_many  :groups, class_name: 'FlightFacade::Records::GroupsRecord'
      has_one   :cluster, class_name: 'FlightFacade::Records::ClustersRecord'

      def to_model
        Models::Node.new(name: name, params: params.reject { |k, _| k[0] == '_' })
      end
    end

    class GroupsRecord < BaseRecord
      attributes :name, :params, :level_params

      has_many  :nodes, class_name: 'FlightFacade::Records::NodesRecord'
      has_one   :cluster, class_name: 'FlightFacade::Records::ClustersRecord'

      def to_model(include_nodes: false)
        if include_nodes
          Models::Group.new(name: name, nodes: nodes.map(&:to_model))
        else
          Models::Group.new(name: name)
        end
      end
    end

    class ClustersRecord < BaseRecord
      attributes :name, :params, :level_params

      has_many  :groups, class_name: 'FlightFacade::Records::GroupsRecord'
      has_many  :nodes, class_name: 'FlightFacade::Records::NodesRecord'
    end
  end
end

