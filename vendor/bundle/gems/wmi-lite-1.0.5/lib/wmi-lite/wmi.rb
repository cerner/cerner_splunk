#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2019 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'win32ole' if RUBY_PLATFORM =~ /mswin|mingw32|windows/
require_relative 'wmi_instance'
require_relative 'wmi_exception'

module WmiLite
  class Wmi
    def initialize(namespace = nil)
      @namespace = namespace.nil? ? "root/cimv2" : namespace
      @connection = nil
    end

    def query(wql_query)
      query_with_context(wql_query)
    end

    def instances_of(wmi_class)
      query_with_context("select * from #{wmi_class}", wmi_class)
    end

    def first_of(wmi_class)
      query_result = start_query("select * from #{wmi_class}", wmi_class)
      first_result = nil
      query_result.each do |record|
        first_result = record
        break
      end
      first_result.nil? ? nil : wmi_result_to_snapshot(first_result)
    end

    private

    def query_with_context(wql_query, diagnostic_class_name = nil)
      results = start_query(wql_query, diagnostic_class_name)

      result_set = []

      results.each do |result|
        result_set.push(wmi_result_to_snapshot(result))
      end

      result_set
    end

    def start_query(wql_query, diagnostic_class_name = nil)
      result = nil
      connect_to_namespace
      begin
        result = @connection.ExecQuery(wql_query)
        raise_if_failed(result)
      rescue WIN32OLERuntimeError => native_exception
        raise WmiException.new(native_exception, :ExecQuery, @namespace, wql_query, diagnostic_class_name)
      end
      result
    end

    def raise_if_failed(result)
      # Attempting to access the count property of the underlying
      # COM (OLE) object will trigger an exception if the query
      # was unsuccessful.
      result.count
    end

    def connect_to_namespace
      if @connection.nil?
        namespace = @namespace.nil? ? "root/cimv2" : @namespace
        locator = WIN32OLE.new("WbemScripting.SWbemLocator")
        begin
          @connection = locator.ConnectServer(".", namespace)
        rescue WIN32OLERuntimeError => native_exception
          raise WmiException.new(native_exception, :ConnectServer, @namespace)
        end
      end
    end

    def wmi_result_to_snapshot(wmi_object)
      snapshot = Instance.new(wmi_object)
    end
  end
end
