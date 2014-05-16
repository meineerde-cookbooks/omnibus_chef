# encoding: utf-8

# Set the version to install or a full URL to download the Omnibus package
#
# EITHER set the version to download and install
# By default, we install the latest package available
default['omnibus_chef']['version'] = 'latest'
default['omnibus_chef']['prerelease'] = false
default['omnibus_chef']['nightlies'] = false

# OR set the full URL to download the desired Omnibus package
# If this is set, we use the download URL and ignore any other version settings
default['omnibus_chef']['download_url'] = nil

default['omnibus_chef']['machine'] = node['kernel']['machine']
case
when node['platform'] == 'amazon'
  default['omnibus_chef']['platform'] = 'el'
  default['omnibus_chef']['platform_version'] = 6
when node['platform'] == 'debian'
  default['omnibus_chef']['platform'] = node['platform']
  default['omnibus_chef']['platform_version'] = node['platform_version'].to_i
when node['platform_family'] == 'rhel'
  default['omnibus_chef']['platform'] = 'el'
  default['omnibus_chef']['platform_version'] = node['platform_version'].to_i
else
  default['omnibus_chef']['platform'] = node['platform']
  default['omnibus_chef']['platform_version'] = node['platform_version']
end

# If true, we contact the omnitruck API via https. It should give us back
# a https download URL. We can thus be a bit more secure from tampering.
default['omnibus_chef']['use_https'] = true

# Set to true to prevent the installation of a lower version than is
# currently installed.
default['omnibus_chef']['prevent_downgrade'] = false

# Can be one of immediately, delayed
default['omnibus_chef']['when'] = 'immediately'
# When updating immediately, kill the current chef run after an update to
# ensure a clean state for the following cookbooks. During an update,
# internal chef libraries may change, move, or no longer exist. The
# currently running instance can encounter unexpected states because of this.
# To prevent this, the updater will attempt to kill the Chef instance so that
# it can be restarted in a normal state.
default['omnibus_chef']['kill_chef_on_upgrade'] = true

# Restart the chef-client service after an upgrade. This is a good idea when
# using Chef as a service
default['omnibus_chef']['restart_chef_client_service'] = false
