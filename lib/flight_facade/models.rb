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
require 'active_model'

module FlightFacade
  class BaseHashieDashModel
    def self.inherited(klass)
      data_class = Class.new(Hashie::Dash) do
        include Hashie::Extensions::IgnoreUndeclared
        include ActiveModel::Validations

        def self.method_added(m)
          parent.delegate(m, to: :data)
        end
      end

      klass.const_set('DataHash', data_class)
      klass.delegate(*(ActiveModel::Validations.instance_methods - Object.methods), to: :data)
    end

    def self._jsonapi_serializer_class_name
      @jsonapi_serializer_class_name ||= name.split('::').last + 'Serializer'
    end

    def self._type
      @type ||= name.split('::').last.demodulize.tableize.dasherize
    end

    attr_reader :data

    def initialize(*a)
      @data = self.class::DataHash.new(*a)
    end

    def jsonapi_serializer_class_name
      self.class._jsonapi_serializer_class_name
    end

    def type
      self.class._type
    end
  end

  class Node < BaseHashieDashModel
    DataHash.class_exec do
      include Hashie::Extensions::Dash::PropertyTranslation

      property :name,   required: true
      property :params, required: true
      property :ranks,  default: [], transform_with: ->(v) { (v.dup << 'default').uniq }
    end
  end

  class Group < BaseHashieDashModel
    DataHash.class_exec do
      property  :name,  required: true
      property  :nodes, default: []
    end
  end
end

