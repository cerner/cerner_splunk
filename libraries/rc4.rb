# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: rc4.rb

# RC4 implementation in this module is taken from https://github.com/caiges/Ruby-RC4
# (SHA: c4c56511bd4f98312d6cad28c6836dc6043d7453) project under the MIT license below.
#
# The MIT License

# Copyright (C) 2010 Max Prokopiev, Alexandar Simic, Caige Nichols

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module CernerSplunk
  # Implementation of RC4 algorithm
  class RC4
    def initialize(str)
      initialize_state(str)
      @q1 = 0
      @q2 = 0
    end

    def encrypt!(text)
      text.force_encoding('binary').unpack('C*').map do |encoded_byte|
        @q1 = (@q1 + 1) % 256
        @q2 = (@q2 + @state[@q1]) % 256
        @state[@q1], @state[@q2] = @state[@q2], @state[@q1]
        encoded_byte ^ @state[(@state[@q1] + @state[@q2]) % 256]
      end.pack 'C*'
    end

    alias decrypt! encrypt!

    def encrypt(text)
      encrypt!(text.dup)
    end

    alias decrypt encrypt

    private

    # Performs the key-scheduling algorithm to initialize the state.
    def initialize_state(key)
      i = j = 0
      # The initial state which is then modified by the key-scheduling algorithm
      @state = (0..255).to_a
      key = key.force_encoding('binary').unpack('C*')
      key_length = key.length
      while i < 256
        j = (j + @state[i] + key[i % key_length]) % 256
        @state[i], @state[j] = @state[j], @state[i]
        i += 1
      end
    end
  end
end
