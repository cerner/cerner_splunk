#
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

module Mixlib
  module Authentication
    DEFAULT_SERVER_API_VERSION = "0"

    attr_accessor :logger
    module_function :logger, :logger=

    class AuthenticationError < StandardError
    end

    class MissingAuthenticationHeader < AuthenticationError
    end

    class Log
    end

    begin
      require "mixlib/log"
      Mixlib::Authentication::Log.extend(Mixlib::Log)
    rescue LoadError
      require "mixlib/authentication/null_logger"
      Mixlib::Authentication::Log.extend(Mixlib::Authentication::NullLogger)
    end

    Mixlib::Authentication.logger = Mixlib::Authentication::Log
    Mixlib::Authentication.logger.level = :error
  end
end
