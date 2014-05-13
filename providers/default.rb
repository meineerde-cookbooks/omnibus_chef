# encoding: utf-8

use_inline_resources

def self.download_params
  ::OmnibusChef::Omnitruck::ARGUMENTS_MAP.keys
end

def load_current_resource
  @current_resource = Chef::Resource::OmnibusChef.new(@new_resource.name)
  @current_resource.version node['chef_packages']['chef']['version']
end

action :download do
  perform_download!
end

action :install do
  if perform_install?
    perform_download!
    perform_install!
  end
end

def perform_download!
  omnibus_url = download_url
  omnibus_package = download_path

  remote_file download_path do
    source omnibus_url
    path omnibus_package

    backup false
    action :create
  end
end

def perform_install?
  if @new_resource.prevent_downgrade
    new_version = Gem::Version.new(detect_version)
    current_version = Gem::Version.new(@current_resource.version)

    if new_version > current_version
      Chef::Log.debug "#{@new_resource} Current Chef version: #{@current_resource.version}. Upgrading Chef to #{detect_version}."
      true
    elsif new_version == current_version
      Chef::Log.debug "#{@new_resource} Current Chef version: #{@current_resource.version}, same as target version."
      false
    else
      Chef::Log.debug "#{@new_resource} Current Chef version: #{@current_resource.version}. Not attempting to downgrade Chef."
      false
    end
  else
    if detect_version != @current_resource.version
      Chef::Log.debug "#{@new_resource} Current Chef version: #{@current_resource.version}. Upgrading Chef to #{detect_version}."
      true
    else
      Chef::Log.debug "#{@new_resource} Current Chef version: #{@current_resource.version}, same as target version."
      false
    end
  end
end

def perform_install!
  omnibus_package = download_path
  omnibus_version = detect_version

  package_provider = case @new_resource.platform
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

  package omnibus_package do
    provider package_provider
    source omnibus_package
    version omnibus_version
  end
end

private

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

def detect_version
  @detect_version ||= begin
    if @new_resource.version && @new_resource.version != 'latest'
      version = @new_resource.version.to_s.sub(/\-.*$/, '')
    else
      version = download_url.scan(/chef_(\d+\.\d+.\d+)/).flatten.first
    end

    Chef::Log.debug "#{new_resource} Chef target version: #{version}"
    version
  end
end
