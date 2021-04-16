# Copyright (c) 2015 Lamont Granquist
# Copyright (c) 2015 Chef Software, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "rubygems" unless defined?(Gem)

require_relative "encoder"
require_relative "parser"
require "ffi_yajl/ext/dlopen"
require_relative "map_library_name"

# needed so the encoder c-code can find these symbols
require "stringio" unless defined?(StringIO)
require "date"

module FFI_Yajl
  extend FFI_Yajl::MapLibraryName
  extend FFI_Yajl::Ext::Dlopen

  dlopen_yajl_library

  class Parser
    require "ffi_yajl/ext/parser"
    include FFI_Yajl::Ext::Parser
  end

  class Encoder
    require "ffi_yajl/ext/encoder"
    include FFI_Yajl::Ext::Encoder
  end
end
