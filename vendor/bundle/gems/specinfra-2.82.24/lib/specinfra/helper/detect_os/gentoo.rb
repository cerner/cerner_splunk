class Specinfra::Helper::DetectOs::Gentoo < Specinfra::Helper::DetectOs
  def detect
    if run_command('ls /etc/gentoo-release').success?
      { :family => 'gentoo', :release => nil }
    end
  end
end
