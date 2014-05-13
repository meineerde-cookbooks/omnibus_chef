# encoding: utf-8

if platform?('debian') && Gem::Version.new(node['platform_version']) < Gem::Version.new('6.0.0')
  Chef::Log.warn 'Omnibus Chef does not support Debian 5. Doing nothing'
  return
end

ruby_block "delay omnibus_chef #{node['omnibus_chef']['version']}" do
  action node['omnibus_chef']['when'] == 'delayed' ? :run : :nothing
  notifies :install, "omnibus_chef[#{node['omnibus_chef']['version']}]", :delayed
end

ruby_block 'kill_chef_on_upgrade' do
  action :nothing
  block do
    Chef::Application.fatal!('New Omnibus Chef version installed. Killing Chef run!')
  end
end

omnibus_chef node['omnibus_chef']['version'].to_s do
  action node['omnibus_chef']['when'] == 'delayed' ? :nothing : :install

  download_url node['omnibus_chef']['download_url']
  prevent_downgrade node['omnibus_chef']['prevent_downgrade']

  Chef::Provider::OmnibusChef.download_params.each do |param|
    send param, node['omnibus_chef'][param]
  end

  if node['omnibus_chef']['restart_chef_client_service']
    notifies :restart, 'service[chef-client]', :immediately
  end

  if node['omnibus_chef']['kill_chef_on_upgrade'] && node['omnibus_chef']['when'] != 'delayed'
    notifies :run, 'ruby_block[kill_chef_on_upgrade]', :immediately
  end
end
