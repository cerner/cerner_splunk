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

module WmiLite
  class WmiException < RuntimeError
    def initialize(exception, wmi_method_context, namespace, query = nil, class_name = nil)
      error_message = exception.message
      error_code = translate_error_code(error_message)

      case wmi_method_context
      when :ConnectServer
        error_message = translate_wmi_connect_error_message(error_message, error_code, namespace)
      when :ExecQuery
        error_message = translate_query_error_message(error_message, error_code, namespace, query, class_name)
      end

      super(error_message)
    end

    private

    def translate_error_code(error_message)
      error_code = nil

      # Parse the error to get the error status code
      error_code_match = error_message.match(/[^\:]+\:\s*([0-9A-Fa-f]{1,8}).*/)
      error_code = error_code_match.captures.first if error_code_match
      error_code ? error_code : ""
    end

    def translate_wmi_connect_error_message(native_message, error_code, namespace)
      error_message = "An error occurred connecting to the WMI service for namespace \'#{namespace}\'. The namespace may not be valid, access may not be allowed to the WMI service, or the WMI service may not be available.\n#{native_message}"

      if error_code =~ /8004100E/i
        error_message = "The specified namespace name \'#{namespace}\' is not a valid namespace name or does not exist.\n#{native_message}"
      end

      error_message
    end

    def translate_query_error_message(native_message, error_code, namespace, query, class_name)
      error_message = "An error occurred when querying namespace \'#{namespace}\' with query \'#{query}\'.\n#{native_message}"

      error_code = translate_error_code(error_message)

      # Use the status code to generate a more friendly message
      case error_code
      when /80041010/i
        if class_name
          error_message = "The specified class \'#{class_name}\' is not valid in the namespace \'#{namespace}\'.\n#{native_message}."
        else
          error_message = "The specified query \'#{query}\' referenced a class that is not valid in the namespace \'#{namespace}\'\n#{native_message}."
        end
      when /80041017/i
        error_message = "The specified query \'#{query}\' in namespace \'#{namespace}\' is not a syntactically valid query.\n#{native_message}"
      end

      error_message
    end
  end
end
