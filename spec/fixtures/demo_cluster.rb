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

module FlightFacade
  module DemoCluster
    def self.nodes_data
      {
        'single' => {},
        'double1' => {},
        'double2' => {},
        'param_test' => {
          params: {
            'key1' => 'value1',
            'key2' => 'value2'
          }
        },
        'underscore_param_test' => {
          params: {
            '_underscored_key': 'this key should be removed'
          }
        }
      }
    end

    def self.groups_data
      {
        'empty' => {},
        'singles' => { nodes: ['single'] },
        'doubles' => { nodes: ['double1', 'double2'] }
      }
    end
  end
end

