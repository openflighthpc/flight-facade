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

require "bundler/setup"
require "flight_facade"
require 'vcr'

require_relative 'fixtures/demo_cluster'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('[REDACTED]') do |interaction|
    interaction.request.headers['Authorization'].first
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  FACADE_CLASSES = [
    FlightFacade::Facades::NodeFacade,
    FlightFacade::Facades::GroupFacade
  ]
  def with_facade_dummies
    old_facades = FACADE_CLASSES.map do |klass|
      old = begin
              klass.facade_instance
            rescue NotImplementedError
              nil
            end
      [klass, old]
    end
    FACADE_CLASSES.each { |c| c.facade_instance = c::Dummy.new }
    yield if block_given?
  ensure
    old_facades.each { |c, o| c.facade_instance = o }
  end

  def with_vcr(cassette = nil)
    # NOTE: *READ ME FUTURE DEVS*
    # The following line should be commented out *most of the time. This prevents VCR
    # from making any new requests that it doesn't recognised. In theory, the app should
    # make the same requests each time.
    #
    # * It is acceptable to uncomment the line when adding new specs IF you need to make
    # a new request. However please comment it out once you are done
    #
    # @vcr_record_mode = :new_episodes

    VCR.use_cassette(cassette || 'default',
                     record: @vcr_record_mode || :once,
                     allow_playback_repeats: true) do
      yield if block_given?
    end
  end
end

