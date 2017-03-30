
# frozen_string_literal: true

#
# Cookbook Name:: odw_cron
# Resource:: sh_cluster
#

# TODO: What is this
provides :sh_cluster

actions :initialize, :add, :remove
default_action :add
attribute :search_heads, kind_of: Array
attribute :admin_password, kind_of: String
