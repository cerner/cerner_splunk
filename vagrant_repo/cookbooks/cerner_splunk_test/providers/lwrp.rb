use_inline_resources

action :go do
  cerner_splunk_forwarder_monitors new_resource.name do
    app new_resource.app
    index new_resource.index unless new_resource.index.nil?
    monitors new_resource.monitors
  end
end
