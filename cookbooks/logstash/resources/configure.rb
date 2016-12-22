property :instance_name, String, name_property: true

property :install_path, String, default: nil
property :logstash_user, String, default: lazy { |r| "logstash_#{r.instance_name}" }
property :logstash_group, String, default: lazy { |r| "logstash_#{r.instance_name}" }

default_action :configure

action :configure do
  # configure is located at package path
  yml_path = "/etc/logstash/logstash.yml"
  unless new_resource.install_path.nil?
    yml_path = "#{install_path}/conf/logstash.yml"
  end
  Chef::Log.info("Configure #{yml_path} to #{new_resource.instance_name}")
  template "#{yml_path}" do
    mode '0644'
    source 'logstash.yml.erb'
    cookbook 'logstash'
    variables(
      node_name: new_resource.instance_name,
      path_data: node['logstash']['path_data'],
      path_config: node['logstash']['path_config'],
      http_port: node['logstash']['http_port'],
      http_host: node['logstash']['http_host'],
      pipeline_workers: node['logstash']['pipeline_workers'],
      pipeline_output_workers: node['logstash']['pipeline_output_workers'],
      pipeline_batch_size: node['logstash']['pipeline_batch_size'],
      pipeline_batch_delay: node['logstash']['pipeline_batch_delay'],
      pipeline_unsafe_shutdown: node['logstash']['pipeline_unsafe_shutdown'],
      path_logs: node['logstash']['path_logs'],
      path_plugins: node['logstash']['path_plugins']
    )
    notifies :restart, "service[#{new_resource.instance_name}]", :immediately
  end

end
