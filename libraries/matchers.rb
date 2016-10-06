if defined?(ChefSpec)
  ChefSpec.define_matcher :splunk_app

  def create_splunk_app(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:splunk_app, :create, resource)
  end

  def remove_splunk_app(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:splunk_app, :remove, resource)
  end

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
