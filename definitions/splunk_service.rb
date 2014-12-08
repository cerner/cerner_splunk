# Declares the 
define :splunk_service, :resource_name => nil, :action => :nothing do
  if platform_family?('windows')
    service_name = 'SplunkForwarder'
  else
    service_name = 'splunk'
  end
  
  resource_name = params[:resource_name] || params[:name]
  service resource_name do
    service_name service_name
    action params[:action]
    supports status: true, start: true, stop: true, restart: true
  end
end