include CernerSplunk::RestartHelpers

module CernerSplunk
  module Restart
    def override_install_dir
      CernerSplunk.splunk_home(node['platform_family'], node['kernel']['machine'], node['splunk']['package']['base_name'])
    end

    def override_name
      'splunk'
    end

    def ensure_restart
      install_dir = override_install_dir
      name = override_name
      CernerSplunk::RestartHelpers.ensure_restart
    end
  end
end
