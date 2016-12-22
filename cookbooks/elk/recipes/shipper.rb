include_recipe "java"

logstash_install 'shipper' do
  action :install
end

logstash_configure 'shipper' do
  action :configure
end

template "/etc/logstash/conf.d/logstash_shipper.conf" do
  mode '0644'
  source 'logstash_shipper.conf.erb'
  cookbook 'elk'
end

service "shipper" do
  action [:enable, :start]
end
