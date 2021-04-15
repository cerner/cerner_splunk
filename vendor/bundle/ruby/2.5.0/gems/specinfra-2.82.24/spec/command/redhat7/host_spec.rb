require 'spec_helper'

property[:os] = nil
set :os, :family => 'redhat', :release => '7'


describe get_command(:check_host_is_reachable, 'example.jp', '53', 'udp', 2) do 
  it { should eq "ncat -vvvvu example.jp 53 -w 2 -i 2 2>&1 | grep -q SUCCESS" } 
end

describe get_command(:check_host_is_reachable, 'example.jp', '80', 'tcp', 3) do 
  it { should eq "ncat -vvvvt example.jp 80 -w 3 -i 3 2>&1 | grep -q SUCCESS" } 
end

describe get_command(:get_host_ipaddress, 'pink.unicorn.com') do 
  it { should eq "getent hosts pink.unicorn.com | awk '{print $1}'" }
end

describe get_command(:get_host_ipv4_address, 'pink.unicorn.com') do 
  it { should eq "getent ahostsv4 pink.unicorn.com | awk '{print $1; exit}'" } 
end 

describe get_command(:get_host_ipv6_address, 'pink.unicorn.com') do 
  it { should eq "getent ahostsv6 pink.unicorn.com | awk '{print $1; exit}'" } 
end 
