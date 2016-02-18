# In order to work on chef 11.x the file must be here rather than under matchers/splunk_template.rb
if defined?(ChefSpec)
  ChefSpec.define_matcher :create_splunk_template

  def create_splunk_template(resource)
    # Names of resources in the resource collection work differently in Chef 11.x vs. 12.x.
    provider_resolver_defined = defined?(Chef::ProviderResolver) == 'constant' && Chef::ProviderResolver.class == Class
    if provider_resolver_defined
      ChefSpec::Matchers::ResourceMatcher.new(:splunk_template, :create, resource)
    else
      ChefSpec::Matchers::ResourceMatcher.new(:template, :create, resource)
    end
  end
end
