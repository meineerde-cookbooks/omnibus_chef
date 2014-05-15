# encoding: utf-8

actions :install, :download
default_action :install

attribute :download_url, :kind_of => [String, NilClass]
attribute :cache_path, :kind_of => [String], :default => Chef::Config[:file_cache_path]

attribute :platform, :kind_of => [String, NilClass]
attribute :platform_version, :kind_of => [String, Numeric, NilClass]
attribute :machine, :kind_of => [String, NilClass]
attribute :version, :kind_of => [String], :default => 'latest'
attribute :prerelease, :kind_of => [TrueClass, FalseClass], :default => false
attribute :nightlies, :kind_of => [TrueClass, FalseClass], :default => false

# Set to true to prevent the installation of a lower version than is
# currently installed. This attribute is only relevant for the install action
# and is ignored for the download action.
attribute :prevent_downgrade, :kind_of => [TrueClass, FalseClass], :default => false
