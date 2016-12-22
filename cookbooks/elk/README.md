# Overview
This guide will teach you step by step to create a Elasticsearch-Logstash platform by using Chef

## Beginner guide
This guide is look different from many Chef tutorials cause this guide use only the lastest version of ChefDK (0.19.6)
Many tools are obsulated or merged into a part of ChefDK.
The best source and up to date document is here https://docs.chef.io/release/devkit/

To test Chef on local machine, follow the steps below

1) Install VirtualBox 
https://www.virtualbox.org/wiki/Downloads

2) Install Vagrant. Vagrant is a tool to manage VM. 
https://learn.chef.io/tutorials/learn-the-basics/rhel/virtualbox/set-up-a-machine-to-manage/

Install Vagrant to create VM
```bash
vagrant box add bento/centos-7.2 --provider=virtualbox
vagrant init bento/centos-7.2
vagrant plugin install vagrant-scp
```

Local remote into created VM
```
vagrant up
vagrant ssh
```

3) Install ChefDK. On remote machine...

```bash
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chefdk -c stable -v 0.18.30
sudo yum -y install ruby
sudo yum -y install git
```

4) Create Chef repository

```bash
chef generate repo REPO_NAME
```

The directory of Chef repo should be
```
.
├── LICENSE
├── README.md
├── chefignore
├── cookbooks
│   ├── README.md
│   └── example
│       ├── README.md
│       ├── attributes
│       │   └── default.rb
│       ├── metadata.rb
│       └── recipes
│           └── default.rb
├── data_bags
│   ├── README.md
│   └── example
│       └── example_item.json
├── environments
│   ├── README.md
│   └── example.json
└── roles
    ├── README.md
    └── example.json

```

5) Import required cookbooks and create a local repository using Berks. Berks is already bundle with ChefDK.

Edit Berksfile. The code below will tell the Berks to download java cookbooks from Chef repository `https://supermarket.chef.io`
And download `elasticsearch` from GitHub repository

```bash
cd REPO_NAME
```
```bash
vi Berksfile
```

```
source 'https://supermarket.chef.io'

cookbook 'elasticsearch', github: 'elastic/cookbook-elasticsearch'
cookbook 'java'
```

Download all dependency cookbooks

```bash
berks install
```

Copy downloaded cookbooks to local repository (the repositoriy we just created on step 2)

```bash
berks vendor cookbooks
```

6) Create new Chef cookbook for ELK

```bash
cd REPO_NAME
```
```bash
chef generate cookbook cookbooks/elk
```

Now the directory will be
```
.
├── LICENSE
├── README.md
|-- Berksfile
├── chefignore
├── cookbooks
│   ├── README.md
│   ├── elk
│   │   ├── Berksfile
│   │   ├── README.md
│   │   ├── chefignore
│   │   ├── metadata.rb
│   │   ├── recipes
│   │   │   └── default.rb
│   │   ├── spec
│   │   │   ├── spec_helper.rb
│   │   │   └── unit
│   │   │       └── recipes
│   │   │           └── default_spec.rb
│   │   └── test
│   │       └── recipes
│   │           └── default_test.rb
│   └── example
│       ├── README.md
│       ├── attributes
│       │   └── default.rb
│       ├── metadata.rb
│       └── recipes
│           └── default.rb
├── data_bags
│   ├── README.md
│   └── example
│       └── example_item.json
├── environments
│   ├── README.md
│   └── example.json
└── roles
    ├── README.md
    └── example.json
```


7) Edit the `metadata.rb` under `cookbooks/elk`. This file contains cookbook dependencies.

Note: Berksfile (Chef dependency manager) uses `Berksfile` but Chef-Client uses `metadata.rb`. This is so confusing.

```
name 'elk'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures elk'
long_description 'Installs/Configures elk'
version '0.1.0'

depends 'elasticsearch'
depends 'java'
```

Creates `attributes/java.rb` to change default Java distribution to Oracle Java. 
I would suggest to install Oracle Java. Its performance and stability is better than other distribution.
And Java8 is recommended for Elasticsearch. The performance and GC is must better than Java7

```bash
mkdir cookbooks/elk/attributes
vi cookbooks/elk/attributes/java.rb
```

```
normal['java']['jdk_version'] = '8'
normal['java']['install_flavor'] = 'oracle'
normal['java']['oracle']['accept_oracle_download_terms'] = true
```

8) Test new cookbook
```bash
sudo chef-client --local-mode --runlist "recipe[elk]"
```

## Create Elasticsearch Cookbook

1) First, we need to edit the Vagrantfile in order to allow VM to communicate with Host machine
Edit the Vagrantfile 

```ruby
Vagrant.configure("2") do |config|
  config.berkshelf.enabled = true
  config.vm.network "private_network", ip: "10.1.0.101"
  config.vm.network "forwarded_port", guest: 9200, host: 9200, auto_correct: true
  config.vm.network "forwarded_port", guest: 9300, host: 9300, auto_correct: true
  config.vm.box = "bento/centos-7.2"
end
```

2) We need to increase a VM memory, we need at least 1GB for starting Elasticsearch
If VM is running, stop the VM by the following command

```bash
vagrant halt
```

Go to Vitualbox and change the allocated memory to 1024MB
To start vagrant again

```bash
vagrant up
```

3) Create a recipes.

Create a new file "elasticsearch.rb" 

```bash
vi cookbooks/elk/recipes/elasticsearch.rb
```

Since elasticsearch cookbook already provide all default template for setting up Elasticsearch. If you just want everything to be default, just include "elasticsearch".

The cookbook will be

```ruby
include_recipe "java"
include_recipe "elasticsearch"
```

This will install the lastest version of Elasticsearch from package, create default user and use all default configuration from "elasticsearch.yml"

If you want to configure something, you need to override some script below. ("Override attributes is not working. Possibly a bug of elasticsesarch chief script")

```ruby
include_recipe "java"

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
    'network.host' => '0.0.0.0', # Bind to all network address
    # 'network.host' => node['ipaddress'],
    'node.max_local_storage_nodes' => 1
  })
end

# Start the service
elasticsearch_service 'elasticsearch' do
  service_actions [:enable, :start]
end
```

8) Test new cookbook/recipie

```bash
sudo chef-client --local-mode --runlist "recipe[elk::elasticsearch]"
```

4) Test connection with Host machine.

Retrive published address of VM

```bash
ifconfig
```

The result should be

```
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        ether 08:00:27:0c:4e:dc  txqueuelen 1000  (Ethernet)
        RX packets 1989  bytes 168478 (164.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1224  bytes 138558 (135.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

enp0s8: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.1.0.101  netmask 255.255.255.0  broadcast 10.1.0.255
        ether 08:00:27:cf:d8:43  txqueuelen 1000  (Ethernet)
        RX packets 275  bytes 52226 (51.0 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 23  bytes 2446 (2.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 0  (Local Loopback)
        RX packets 92  bytes 7369 (7.1 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 92  bytes 7369 (7.1 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

5) Then from Host machine, run the following command

```bash
curl 10.0.2.15:9200
```

The result should be

```
{
  "name" : "localhost",
  "cluster_name" : "elk",
  "cluster_uuid" : "YB4tiDJOTNCA1AKK0VByww",
  "version" : {
    "number" : "5.0.0",
    "build_hash" : "253032b",
    "build_date" : "2016-10-26T04:37:51.531Z",
    "build_snapshot" : false,
    "lucene_version" : "6.2.0"
  },
  "tagline" : "You Know, for Search"
}
```
