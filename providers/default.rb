# encoding: utf-8

def self.download_params
  ::OmnibusChef::Omnitruck::ARGUMENTS_MAP.keys
end

action :download do
  download = perform_download!

  @new_resource.updated_by_last_action(download.updated_by_last_action?)
end

action :install do
  if perform_install?
    download = perform_download!
    install = perform_install!

    @new_resource.updated_by_last_action(
      download.updated_by_last_action? ||
      install.updated_by_last_action?
    )
  end
end

def perform_download!
  Chef::Log.info "#{@new_resource} downloading #{download_url}"

  remote_file = Chef::Resource::RemoteFile.new(download_path, run_context)
  remote_file.source(download_url)
  remote_file.path(download_path)
  remote_file.mode('0644')
  remote_file.backup(false)
  remote_file.run_action(:create)

  remote_file
end

def perform_install?
  current = current_version.split('-', 2)
  current[0] = Gem::Version.new(current[0])
  current[1] = current[1].to_i

  candidate = new_version.split('-', 2)
  candidate[0] = Gem::Version.new(candidate[0])
  if current[0] == candidate[0] && candidate[1].nil?
    candidate[1] = current[1]
  else
    candidate[1] = candidate[1].to_i
  end

  if @new_resource.prevent_downgrade
    case candidate <=> current
    when 1
      Chef::Log.debug "#{@new_resource} upgrade to version #{new_version}"
      true
    when 0
      Chef::Log.debug "#{@new_resource} is already installed - nothing to do"
      false
    when -1
      Chef::Log.debug "#{@new_resource} not attempting downgrading chef"
      false
    end
  else
    if candidate != current
      Chef::Log.debug "#{@new_resource} installing new version #{new_version}"
      true
    else
      Chef::Log.debug "#{@new_resource} is already installed - nothing to do"
      false
    end
  end
end

def perform_install!
  package = Chef::Resource::Package.new(download_path, run_context)
  package.provider(package_provider)
  package.source(download_path)
  package.version(new_version)
  package.run_action(:install)

  package
end

private

def current_version
  @current_version ||= begin
    # Build a dummy package resource to find the currently installed version
    # of the Chef package
    chef_resource = Chef::Resource::Package.new('chef')
    chef_package = package_provider.new(chef_resource, run_context)
    chef_package.load_current_resource

    if current_version = chef_package.current_resource.version
      Chef::Log.debug "#{@new_resource} current version is #{current_version}"
    else
      Chef::Log.debug "#{@new_resource} currently not installed"
    end
    current_version
  end
end

def new_version
  @new_version ||= begin
    if @new_resource.version && @new_resource.version != 'latest' && !@new_resource.download_url
      # The Omnitruck API doesn't support build versions
      new_version = @new_resource.version.to_s.sub(/\-.*$/, '')
    else
      new_version = download_url.scan(/chef_(\d+\.\d+.\d+-\d+)/).flatten.first
      fail 'Could not detect chef version from download_url' unless @new_version
    end

    Chef::Log.debug "#{@new_resource} candidate version is #{new_version}"
    new_version
  end
end

def download_url
  @download_url ||= begin
    @new_resource.download_url ||
    ::OmnibusChef::Omnitruck.new(node).client_url(url_params)
  end
end

def download_path
  ::File.join @new_resource.cache_path, ::File.basename(download_url)
end

def url_params
  @url_params ||= self.class.download_params.each_with_object({}) do |param, hash|
    if param == :version
      value = @new_resource.version == 'latest' ? '' : @new_resource.version
    else
      value = @new_resource.send(param)
    end
    hash[param.to_sym] = value
  end
end

def package_provider
  case @new_resource.platform
  when 'debian', 'ubuntu'
    Chef::Provider::Package::Dpkg
  when 'el', 'suse', 'sles'
    Chef::Provider::Package::Rpm
  when 'freebsd'
    Chef::Provider::Package::Freebsd
  when 'mac_os_x'
    # On OS X, we expect the dmg cookbook to be available
    Chef::Provider::DmgPackage
  when 'solaris2'
    # TODO: properly handle the different solaris flavors
    Chef::Provider::Package::Solaris
  when 'windows'
    Chef::Provider::Package::Windows
  else
    fail "Unknown platform #{platform}"
  end
end
