if defined?(ChefSpec)
  def create_splunk_template(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:splunk_template, :create, resource)
  end

  def create_splunk_app(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:splunk_app, :create, resource)
  end

  def remove_splunk_app(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:splunk_app, :remove, resource)
  end
end
