# frozen_string_literal: true

if defined?(ChefSpec)
  def initialize_sh_cluster(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:cerner_splunk_sh_cluster, :initialize, resource)
  end

  def add_sh_member(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:cerner_splunk_sh_cluster, :add, resource)
  end

  def remove_sh_member(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:cerner_splunk_sh_cluster, :remove, resource)
  end
end
