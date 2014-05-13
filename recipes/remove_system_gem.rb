# encoding: utf-8

gem_package 'chef' do
  action :purge
  not_if do
    Chef::Provider::Package::Rubygems.new(
      Chef::Resource::GemPackage.new('dummy')
    ).is_omnibus?
  end
end
