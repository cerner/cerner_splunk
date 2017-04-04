# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: unit_converter.rb
#
# Module contains different functions used to manipulate the units of file sizes.
#
module CernerSplunk
  SIZE_SCALE = %w[KB MB GB TB].freeze
  REGEX = /(?i)^\s*+(\d++(?>\.\d+)?+)\s*+([kmgt](?>i?+b)?+|b?+)\s*+$/
  POWER = { '' => 0, 'B' => 0, 'K' => 1, 'M' => 2, 'G' => 3, 'T' => 4 }.freeze
  # Methods converts file sizes in KB, MB, GB and TB into Bytes.
  def self.convert_to_bytes(string)
    matchdata = string.match REGEX
    fail "Unparsable size input #{string}" unless matchdata

    size = matchdata[1].to_f
    unit = matchdata[2].upcase[0, 1]

    (size * 1024**POWER[unit]).floor
  end

  # Function returns the size in a human readable format.
  def self.human_readable_size(filesize)
    level = 0
    human_size = filesize.fdiv(1024.0)
    while human_size.fdiv(1024.0) > 0.5 && level + 1 < SIZE_SCALE.length
      human_size = human_size.fdiv(1024.0)
      level += 1
    end
    "#{human_size.round(2)} #{SIZE_SCALE[level]}"
  end
end
