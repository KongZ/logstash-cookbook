include_recipe "java"

logstash_install 'indexer' do
  action :install
end

logstash_configure 'indexer' do
  action :configure
end

template "/etc/logstash/conf.d/logstash_indexer.conf.conf" do
  mode '0644'
  source 'logstash_indexer.conf.erb'
  cookbook 'elk'
end

service "indexer" do
  action [:enable, :start]
end
