default['logstash']['path_data'] = "/var/lib/logstash"
default['logstash']['path_config'] = "/etc/logstash/conf.d"
default['logstash']['http_port'] = "9600-9700"
default['logstash']['http_host'] = "127.0.0.1"
default['logstash']['pipeline_workers'] = nil #2
default['logstash']['pipeline_output_workers'] = nil #1
default['logstash']['pipeline_batch_size'] = nil #125
default['logstash']['pipeline_batch_delay'] = nil # 5
default['logstash']['pipeline_unsafe_shutdown'] = false
default['logstash']['path_logs'] = "/var/log/logstash"
default['logstash']['path_plugins'] = nil