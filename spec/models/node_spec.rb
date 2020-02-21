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

require 'spec_helper'

RSpec.describe FlightFacade::Models::Node do
  describe '::ranks' do
    let('other_ranks') { ['rank1', 'rank2'] }

    it 'has a default array' do
      node = described_class.new(name: 'node', params: {})
      expect(node.ranks).to contain_exactly('default')
    end

    it 'can be set from the params' do
      node = described_class.new(name: 'node', params: { ranks: other_ranks })
      expect(node.ranks).to eq([*other_ranks, 'default'])
    end

    it 'removes duplicate ranks' do
      node = described_class.new(name: 'node', params: { ranks: [*other_ranks, *other_ranks] })
      expect(node.ranks).to contain_exactly(*other_ranks, 'default')
    end
  end
end

