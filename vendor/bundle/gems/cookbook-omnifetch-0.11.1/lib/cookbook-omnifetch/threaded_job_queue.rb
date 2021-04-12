# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

module CookbookOmnifetch

  # This class is copied from the Chef codebase:
  # https://github.com/chef/chef/blob/7f0b5150c32994b4ad593505172c5834a984b087/lib/chef/util/threaded_job_queue.rb
  #
  # We do not re-use the code from Chef because we do not want to introduce a
  # dependency on Chef in this library.
  class ThreadedJobQueue
    def initialize
      @queue = Queue.new
      @lock = Mutex.new
    end

    def <<(job)
      @queue << job
    end

    def process(concurrency = 10)
      workers = (1..concurrency).map do
        Thread.new do
          loop do
            fn = @queue.pop
            fn.arity == 1 ? fn.call(@lock) : fn.call
          end
        end
      end
      workers.each { |worker| self << Thread.method(:exit) }
      workers.each(&:join)
    end
  end
end
