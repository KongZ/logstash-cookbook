property :instance_name, String, name_property: true
property :version, String, default: '5.0.0'
property :logstash_user, String, default: lazy { |r| "logstash_#{r.instance_name}" }
property :logstash_group, String, default: lazy { |r| "logstash_#{r.instance_name}" }
property :package_base_path, String, default: 'https://artifacts.elastic.co/downloads/logstash/'
property :checksum_base_path, String, default: 'https://artifacts.elastic.co/downloads/logstash/'
property :platform, String, default: node["platform"]
property :install_path, String, default: "."
# internal use
property :package_uri, String
property :package_type, String, default: 'rpm'

default_action :install
###
# Helper class
### 
action_class do

  ###
  # Fetch the checksum from the mirrors
  ###
  def fetch_checksum
    uri = if new_resource.package_uri.nil?
            URI.join(new_resource.checksum_base_path, "logstash-#{new_resource.version}.#{package_type}.sha1")
          else
            URI("#{new_resource.package_uri}.sha1")
          end
    request = Net::HTTP.new(uri.host, uri.port)
    if uri.to_s.start_with?('https')
      request.use_ssl = true
      request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = request.get(uri)
    if response.code != '200'
      Chef::Log.fatal("Fetching the logstash package checksum at #{uri} resulted in an error #{response.code}")
      raise
    end
    response.body.split(' ')[0]
  rescue => e
    Chef::Log.fatal("Could not fetch the checksum due to an error: #{e}")
    raise
  end

  ###
  # Validate the mirror checksum against the on disk checksum
  # return true if they match. Append .bad to the cached copy to prevent using it next time
  ###
  def validate_checksum(file_to_check)
    desired = fetch_checksum
    actual = Digest::SHA1.hexdigest(::File.read(file_to_check))
    if desired == actual
      true
    else
      Chef::Log.fatal("The checksum of the logstash installation file on disk (#{actual}) does not match the checksum provided from the mirror (#{desired}). Renaming to #{::File.basename(file_to_check)}.bad")
      ::File.rename(file_to_check, "#{file_to_check}.bad")
      raise
    end
  end

  ###
  # Build the complete package URI and handle basepath with/without trailing /
  ### 
  def package_uri 
    uri = ''
    if new_resource.package_uri.nil?
      uri << new_resource.package_base_path
      uri << '/' unless uri[-1] == '/'
      uri << "logstash-#{new_resource.version}.#{package_type}"
    else
      uri << new_resource.package_uri
    end
    log "Downloading file from #{uri}"
    uri
  end
end

load_current_value do
  Chef::Log.info("Package Type #{package_type} on Platform #{node['platform']}")
  if package_type.nil?
    case node["platform"]
      when "redhat", "centos"
        package_type 'rpm'
      when "ubuntu", "debian"
        package_type 'deb'
      else
        package_type 'tar.gz'
    end    
  end
end

action :install do
  group new_resource.logstash_group do    
    append true
    action :create
  end
  
  user new_resource.logstash_group do
    gid new_resource.logstash_group
    shell '/bin/false'
    system true
    action :create
  end

  remote_file "#{Chef::Config[:file_cache_path]}/logstash-#{new_resource.version}.#{package_type}" do
    source package_uri
    show_progress true
    # checksum fetch_checksum # we can't use built-in checksum cause built-in check sum is SHA256
    verify { |file| validate_checksum(file) }
  end

  case package_type
    when 'rpm', 'deb'
      package "logstash" do
        source "#{Chef::Config[:file_cache_path]}/logstash-#{new_resource.version}.#{package_type}"
        provider Chef::Provider::Package::Dpkg
        action :install
      end

      template "/etc/logstash/startup.options" do
        mode '0644'
        source 'startup.options.erb'
        cookbook 'logstash'
        variables(
          service_name: new_resource.instance_name,
          ls_user: new_resource.logstash_user,
          ls_group: new_resource.logstash_group,
        )
      end

      execute "change owner of installed dir to #{new_resource.logstash_user}:#{new_resource.logstash_group}" do
        command "chown -R #{new_resource.logstash_user}:#{new_resource.logstash_group} /usr/share/logstash"
        action :run
      end

      execute "change owner of data dir to #{new_resource.logstash_user}:#{new_resource.logstash_group}" do
        command "chown -R #{new_resource.logstash_user}:#{new_resource.logstash_group} /var/lib/logstash"
        action :run
        only_if do ::File.exist?("/var/lib/logstash") end 
      end

      execute "change owner of log dir to #{new_resource.logstash_user}:#{new_resource.logstash_group}" do
        command "chown -R #{new_resource.logstash_user}:#{new_resource.logstash_group} /var/log/logstash"
        action :run
        only_if do ::File.exist?("/var/log/logstash") end
      end

      execute "change owner of config dir to #{new_resource.logstash_user}:#{new_resource.logstash_group}" do
        command "chown -R #{new_resource.logstash_user}:#{new_resource.logstash_group} /etc/logstash/conf.d"
        action :run
        only_if do ::File.exist?("/etc/logstash/conf.d") end
      end

      execute "system-install" do
        command "/usr/share/logstash/bin/system-install"
      end
    when 'tar.gz'
      execute "extract logstash tarball" do
        command "tar -xvzf #{Chef::Config['file_cache_path']}/logstash-#{new_resource.version}.tar.gz -C #{new_resource.install_path}"
        action :run
      end

      execute "change owner of installed dir to #{new_resource.logstash_user}:#{new_resource.logstash_group}" do
        command "chown -R #{new_resource.logstash_user}:#{new_resource.logstash_group} #{new_resource.install_path}"
        action :run
      end

      # create a link that points to the latest version of the instance so we can reference it later
      link "/opt/logstash_#{new_resource.instance_name}" do
        to new_resource.install_path
      end
  end
end

action :create do
end

action :remove do
  rpm_package "logstash" do
    source "#{Chef::Config[:file_cache_path]}/logstash-#{new_resource.version}.#{package_type}"
    action :remove
  end  
end