# Logstash Cookbook

This cookbook is being written and tested on Logstash 5.x. 

# Usage

To use this cookbook, edit `Berkfile` and add the following line

```
cookbook 'logstash', github: 'KongZ/logstash-cookbook'
```

## Attributes

This cookbook uses Oracle JDK, if you want to use OpenJDK change `[install_flavor]` to `openjdk`

```
normal['java']['install_flavor'] = 'openjdk'
```

The `default.rb` contains default configuration for logstash. Please consult logstash documentation.

## logstash_install

This action will install the logstash. You can install multiple logstash on same machine by enter different `SERVICE_NAME`

```ruby
logstash_install 'SERVICE_NAME' do
  action :install
end
```

The action will perform the following steps
* Create an user from `SERVICE_NAME`
* Download logstash package installer version according to `node['platform']` value
* Validate installer checksum
* Execute the installation command
* Change owner of all installed directory and configuration to new user

## logstash_configure

This action will override default configuration settings of `logstash.yml`. If you do not want to change anything, you may skip this action.

```ruby
logstash_configure 'SERVICE_NAME' do
  action :configure
end
```

# Example Recipe

```ruby
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
```

You can find the complete sample cookbook from https://github.com/KongZ/logstash-cookbook/tree/develop/cookbooks/elk
If you want to create your own cookbook for sharing, you can find a useful tutorial from my experience here https://github.com/KongZ/logstash-cookbook/tree/develop/cookbooks
