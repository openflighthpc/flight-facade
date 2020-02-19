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

require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash'

module FlightFacade
  module HasFacade
    extend ActiveSupport::Concern

    included do
      module self::Base
        extend ActiveSupport::Concern

        class_methods do
          def method_added(m)
            self.parent.eigen_class.delegate(m, to: :facade_instance)
          end
        end
      end
    end

    class_methods do
      attr_writer :facade_instance

      def eigen_class
        class << self
          return self
        end
      end

      def facade_instance
        @facade_instance || raise(NotImplementedError)
      end

      def define_facade(name, super_class = Object, &b)
        klass = Class.new(super_class)
        self.const_set(name, klass)
        klass.include(self::Base)
        klass.class_exec(&b) if b
      end
    end
  end
end

