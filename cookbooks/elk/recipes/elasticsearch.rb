include_recipe "java"
#include_recipe "elasticsearch"

# Let package to create an user
elasticsearch_user 'elasticsearch' do
  action :nothing
end

# If you want to create an user by yourself, uncomment code below
# elasticsearch_user 'elasticsearch' do
#   username 'elasticsearch'
#   groupname 'elasticsearch'
#   shell '/bin/bash'
#   comment 'Elasticsearch User'
#   action :create
# end

# Install the elasticsearch package
elasticsearch_install 'elasticsearch' do
  type 'package'
  version '5.0.0'
  action :install
end

# Configure the elasticsearch
elasticsearch_configure 'elasticsearch' do
  allocated_memory '256m'
  memlock_limit 'unlimited'
  max_map_count '65535'
  nofile_limit '65536'
  configuration ({
    'cluster.name' => 'elk',
    'network.host' => '0.0.0.0', #node['ipaddress'],
    'node.max_local_storage_nodes' => 1
  })
end

# Start the service
elasticsearch_service 'elasticsearch' do
  service_actions [:enable, :start]
end