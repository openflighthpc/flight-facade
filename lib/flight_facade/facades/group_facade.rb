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
  module GroupFacade
    include HasFacade

    module Base
      # Query for a Group object by its name alone
      # @param name [String] the name of the group
      # @return [Group] the group object containing the nodes
      # @return [nil] if it could not resolve the name
      def find_by_name(name)
        raise NotImplementedError
      end

      # Query for all the statically available groups. This method may not
      # include all the ephemeral groups available in `find_by_name`
      #
      # @return [Array<Group>] the list of static groups
      def index_all
        raise NotImplementedError
      end
    end

    define_facade('Dummy')

    define_facade('Exploding') do
      EXPLODE_REGEX = /\A(?<leader>[[:alnum:]]+)(\[(?<low>\d+)\-(?<high>\d+)\])?\Z/
      PADDING_REGEX = /0*\Z/

      def self.explode_names(input)
        parts = input.split(',').reject(&:empty?)
        return nil unless parts.all? { |p| EXPLODE_REGEX.match?(p) }
        parts.map do |part|
          captures = EXPLODE_REGEX.match(part).named_captures.reject { |_, v| v.nil? }
          if captures.key?('low')
            leader = captures['leader']
            max_pads = PADDING_REGEX.match(leader).to_s.length
            stripped_leader = leader.sub(PADDING_REGEX, '')
            low = captures['low'].to_i
            high = captures['high'].to_i
            (low..high).map do |index|
              pads = max_pads - index.to_s.length + 1
              "#{stripped_leader}#{'0' * pads if pads > 0}#{index}"
            end
          else
            part
          end
        end.flatten
      end

      def find_by_name(name)
        node_names = self.class.explode_names(name)
        return nil if node_names.nil?
        nodes = node_names.map { |n| NodeFacade.find_by_name(n) }.reject(&:nil?)
        Group.new(name: name, nodes: nodes)
      end

      def index_all
        []
      end
    end
  end
end

