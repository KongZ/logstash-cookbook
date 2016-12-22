# Cookbook list

* elk - a cookbook to install EL (Elasticsearch-Logstash). This cookbook should be able to reuse with any environment
* logstash - a Logstash cookbook

*Note* this repository doesn't have elasticsearch cookbook since it can be download from official elasticsearch cookbook

# How to create new cookbook for sharing

To build a custom resource, the feature was introduced in *Chef 12.5*  It is the recommended approach for all custom resources starting with that version of the chef-client.

To learn more about custom resource https://docs.chef.io/custom_resources.html

## Create a Logstash cookbook

1) Create a new cookbook 
```bash
chef generate cookbook cookbooks/logstash
```

2) Create a new folder 'resources' 

```bash
mkdir -p cookbooks/logstash/resources
```

3) Write a new file 'install.rb'. This will respond for installing Logstash

An example 'install.rb' file in the 'logstash' cookbook is:
```ruby
property :instance_name, String, name_property: true

action :install do
  Chef::Log.info("Installing Logstash node to #{new_resource.instance_name}")

  group new_resource.logstash_group do
    action :create
    append true
  end
  
  user new_resource.logstash_group do
    gid new_resource.logstash_group
    shell '/bin/false'
    system true
    action :create
  end  
end
```

Once built, the resource gets its name from the cookbook and from the file name in the /resources directory, with an underscore (_) separating them. 
Thus the 'install.rb' under 'logstash' cookbook can be invoked in recipe by

```ruby
logstash_install 'mylogstash' do
  action :install
end
```

You should see the output to console similiar like this
```
Installing Logstash node to mylogstash
```

name_property: true allows the value for this property to be equal to the 'name' of the resource block

4) Long story about writing RPM intallation and Tarball

5) Create default template for 'logstash.yml'

Create new folder for template, Chef use 'default' folder for all platform and '#{platform}' folder for platform specific template
```bash
mkdir -p cookbooks/logstash/templates/default
```

Create a new file named 'logstash.yml.erb'. The cookbook uses Embedded Ruby (ERB) template format.

https://docs.chef.io/templates.html

An example of 'logstash.yml.erb'. The following template will insert a 'node.name' property if and only if 'node_name' variable is not null

```
<% unless @node_name.nil? -%>
node.name: <%= @node_name  %>
<% end -%>
```

Then we need to create a custom resource which provide 'node_name' variable to the template

```ruby
property :instance_name, String, name_property: true

action :configure do
  Chef::Log.info("Configure Logstash node to #{new_resource.instance_name}")
  template "/etc/logstash/logstash.yml" do
    mode '0644'
    source 'logstash.yml.erb'
    cookbook 'logstash'
    variables(
      node_name: new_resource.instance_name,
      path_data: node['logstash']['path_data'],
      path_config: node['logstash']['path_config'],
      http_port: node['logstash']['http_port'],
      http_host: node['logstash']['http_host']
    )
  end
end
```

Some variable should be loaded from attributes. So we just write a default value of these attributes in 'attributes/default.rb'

```
default['logstash']['path_data'] = nil
default['logstash']['path_config'] = nil
default['logstash']['http_port'] = "9600-9700"
default['logstash']['http_host'] = "127.0.0.1"
```

6) Create a recipe to install Logstash

If we just use everything from default Logstash, we just need to include logstash recipe e.g.

```ruby
include_recipe "java"
include_recipe "logstash"
```

But usally we always need to configure the logstash such as node name. So the recipe will look like

```ruby
include_recipe "java"

logstash_install 'shipper' do
  package_type 'rpm'
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

service "logstash" do
  action [:enable, :start]
end
```