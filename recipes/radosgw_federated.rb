#
# Author:: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook Name:: ceph
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Federated version of creating keys and setting up radosgw.

# NOTE: This recipe *MUST* be included in the 'radosgw' recipe and not used as a stand alone recipe!

service_type = node['ceph']['mon']['init_style']

# NOTE: This base_key can also be the bootstrap-rgw key (ceph.keyring) if desired but the default is the admin key. Just change it here.
base_key = "/etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring"

# NOTE: If multisite-replication == true then one region and more than one zone will need to exist. Can support
# additional regions if some base logic is changed below but for now just one zone.
# NOTE: If multisite-replication == false then one region and one zone. For example, the one region plus each zone will
# create a region-zone combination which is both region and zone so that the same set of data and it's structure can
# be used for both scenarios.
# NOTE: The region.json file is a little different for no multisite-replication since there is a one-to-one region/zone
# combination. The zone.json is the same for both scenarios.

if node['ceph']['pools']['radosgw']['federated_enable']
  node['ceph']['pools']['radosgw']['federated_zone_instances'].each do |inst|
    keyring = if node['ceph']['pools']['radosgw']['federated_multisite_replication'] == false
                "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.#{inst['region']}-#{inst['name']}.keyring"
              else
                "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"
              end

    file "/var/log/radosgw/#{node['ceph']['cluster']}.client.radosgw.#{inst['region']}-#{inst['name']}.log" do
      owner node['ceph']['owner']
      group node['ceph']['group']
    end

    directory "/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{inst['region']}-#{inst['name']}" do
      owner node['ceph']['owner']
      group node['ceph']['group']
      mode node['ceph']['mode']
      recursive true
      action :create
      not_if "test -d /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{inst['region']}-#{inst['name']}"
    end

    # Check for existing keys first!
    new_key = ''
    ruby_block "check-radosgw-secret-#{inst['name']}" do
      block do
        fetch = Mixlib::ShellOut.new("sudo ceph auth get-key client.radosgw.#{inst['region']}-#{inst['name']} 2>/dev/null")
        fetch.run_command
        key = fetch.stdout
        unless key.to_s.strip.empty?
          new_key = ceph_chef_save_radosgw_inst_secret(key, "#{inst['region']}-#{inst['name']}")
        end
      end
    end

    # If an initial key exists then this will run - for shared keyring file
    unless !new_key.to_s.strip.empty?
      new_key = ceph_chef_radosgw_inst_secret("#{inst['region']}-#{inst['name']}")
      # One last sanity check on the key
      new_key = nil if new_key.to_s.strip.length != 40
    end
    execute 'update-ceph-radosgw-secret' do
      command lazy { "sudo ceph-authtool #{keyring} --name=client.radosgw.#{inst['region']}-#{inst['name']} --add-key=#{new_key} --cap osd 'allow rwx' --cap mon 'allow rwx'" }
      only_if { !new_key.to_s.strip.empty? }
      only_if "test -s #{keyring}"
      sensitive true if Chef::Resource::Execute.method_defined? :sensitive
    end

    execute 'write-ceph-radosgw-secret' do
      command lazy { "sudo ceph-authtool #{keyring} --create-keyring --name=client.radosgw.#{inst['region']}-#{inst['name']} --add-key=#{new_key} --cap osd 'allow rwx' --cap mon 'allow rwx'" }
      only_if { !new_key.to_s.strip.empty? }
      not_if "test -s #{keyring}"
      sensitive true if Chef::Resource::Execute.method_defined? :sensitive
    end

    # If no initial key exists then this will run
    execute 'generate-client-radosgw-secret' do
      command <<-EOH
        sudo ceph-authtool --create-keyring #{keyring} -n client.radosgw.#{inst['region']}-#{inst['name']} --gen-key --cap osd 'allow rwx' --cap mon 'allow rwx'
      EOH
      creates keyring
      not_if { ceph_chef_radosgw_inst_secret("#{inst['region']}-#{inst['name']}") }
      not_if "test -s #{keyring}"
      notifies :create, "ruby_block[save-radosgw-secret-#{inst['name']}]", :immediately
      sensitive true if Chef::Resource::Execute.method_defined? :sensitive
    end

    # Allow all zone keys
    execute 'update-client-radosgw-secret' do
      command <<-EOH
        sudo ceph-authtool #{keyring} -n client.radosgw.#{inst['region']}-#{inst['name']} --gen-key --cap osd 'allow rwx' --cap mon 'allow rwx'
      EOH
      not_if "sudo grep client.radosgw.#{inst['region']}-#{inst['name']} #{keyring}"
      sensitive true if Chef::Resource::Execute.method_defined? :sensitive
    end

    execute "update-client-radosgw-#{inst['region']}-#{inst['name']}-auth" do
      command <<-EOH
        sudo ceph -k #{base_key} auth add client.radosgw.#{inst['region']}-#{inst['name']} -i #{keyring}
      EOH
      not_if "ceph auth list | grep client.radosgw.#{inst['region']}-#{inst['name']}"
      sensitive true if Chef::Resource::Execute.method_defined? :sensitive
    end

    # Saves the key to the current node attribute
    ruby_block "save-radosgw-secret-#{inst['name']}" do
      block do
        fetch = Mixlib::ShellOut.new("sudo ceph-authtool #{keyring} -n client.radosgw.#{inst['region']}-#{inst['name']}  --print-key")
        fetch.run_command
        key = fetch.stdout
        ceph_chef_save_radosgw_inst_secret(key.delete!("\n"), "#{inst['region']}-#{inst['name']}")
      end
      action :nothing
    end

    # Add the region and zone files and remove the default root pools
    if node['ceph']['pools']['radosgw']['federated_multisite_replication'] == true
      template "/etc/ceph/#{inst['region']}-region.json" do
        source 'radosgw-federated-region.json.erb'
        not_if "test -s /etc/ceph/#{inst['region']}-region.json"
      end

      template "/etc/ceph/#{inst['region']}-region-map.json" do
        source 'radosgw-federated-region-map.json.erb'
        not_if "test -s /etc/ceph/#{inst['region']}-region-map.json"
      end

      region_file = "/etc/ceph/#{inst['region']}-region.json"
      region_map_file = "/etc/ceph/#{inst['region']}-region-map.json"
      region = (inst['region']).to_s
      zone = (inst['name']).to_s
    else
      template "/etc/ceph/#{inst['region']}-#{inst['name']}-region.json" do
        source 'radosgw-federated-no-replication-region.json.erb'
        variables lazy {
          {
            :region => (inst['region']).to_s,
            :zone => (inst['name']).to_s,
            :zone_url => (inst['url']).to_s,
            :zone_port => (inst['port']).to_s
          }
        }
        not_if "test -s /etc/ceph/#{inst['region']}-#{inst['name']}-region.json"
      end

      template "/etc/ceph/#{inst['region']}-#{inst['name']}-region-map.json" do
        source 'radosgw-federated-no-replication-region-map.json.erb'
        variables lazy {
          {
            :region => (inst['region']).to_s,
            :zone => (inst['name']).to_s,
            :zone_url => (inst['url']).to_s,
            :zone_port => (inst['port']).to_s
          }
        }
        not_if "test -s /etc/ceph/#{inst['region']}-#{inst['name']}-region-map.json"
      end

      region_file = "/etc/ceph/#{inst['region']}-#{inst['name']}-region.json"
      region_map_file = "/etc/ceph/#{inst['region']}-#{inst['name']}-region-map.json"
      region = "#{inst['region']}-#{inst['name']}"
      zone = "#{inst['region']}-#{inst['name']}"
    end

    if node['ceph']['pools']['radosgw']['federated_enable_regions_zones']
      template "/etc/ceph/#{zone}-zone.json" do
        source 'radosgw-federated-zone.json.erb'
        variables lazy {
          {
            :region => (inst['region']).to_s,
            :zone => (inst['name']).to_s,
            :secret_key => '',
            :access_key => ''
          }
        }
        not_if "test -s /etc/ceph/#{zone}-zone.json"
      end

      execute "region-set-#{inst['region']}" do
        command <<-EOH
          sudo radosgw-admin region set --infile #{region_file} --rgw-region #{region} --name client.radosgw.#{inst['region']}-#{inst['name']}
        EOH
        # not_if "sudo radosgw-admin region list --name client.radosgw.#{inst['region']}-#{inst['name']} | grep #{inst['region']}"
      end

      execute "region-map-set-#{inst['region']}" do
        command <<-EOH
          sudo radosgw-admin region-map set --infile #{region_map_file} --rgw-region #{region} --name client.radosgw.#{inst['region']}-#{inst['name']}
        EOH
        # not_if "sudo radosgw-admin region-map get --name client.radosgw.#{inst['region']}-#{inst['name']} | grep #{inst['region']}"
      end

      # execute 'remove-default-region' do
      #  command lazy { "rados -p .#{inst['region']}.rgw.root rm region_info.default" }
      #  ignore_failure true
      #  not_if "rados -p .#{inst['region']}.rgw.root ls | grep region_info.default"
      # end

      # execute 'remove-default-zone' do
      #  command lazy { "rados -p .#{inst['region']}-#{inst['name']}.rgw.root rm zone_info.default" }
      #  ignore_failure true
      #  not_if "rados -p .#{inst['region']}-#{inst['name']}.rgw.root ls | grep zone_info.default"
      # end

      execute "zone-set-#{inst['name']}" do
        command <<-EOH
          sudo radosgw-admin zone set --rgw-zone=#{inst['region']}-#{inst['name']} --infile /etc/ceph/#{zone}-zone.json --name client.radosgw.#{inst['region']}-#{inst['name']}
        EOH
        # not_if "sudo radosgw-admin zone list --name client.radosgw.#{inst['region']}-#{inst['name']} | grep #{inst['name']}"
      end

      execute "create-region-defaults-#{inst['region']}" do
        command <<-EOH
          sudo radosgw-admin region default --rgw-region=#{region} --name client.radosgw.#{inst['region']}-#{inst['name']}
          sudo radosgw-admin region-map update --rgw-region #{region} --name client.radosgw.#{inst['region']}-#{inst['name']}
        EOH
      end
    end

    # execute "update-regionmap-#{inst['name']}" do
    #  command <<-EOH
    #    sudo radosgw-admin regionmap update --name client.radosgw.#{inst['region']}-#{inst['name']}
    #  EOH
    # end

    # FUTURE: Update the keys for the zones. This will allow each one to sync with the other.
    # ceph_chef_secure_password(20)
    # ceph_chef_secure_password(40)
    # Will need to create radosgw-admin user with --system so that each zone has a system user so that they can
    # communicate with each other for replication

    # This is only here as part of completeness. The service_type is not really needed because of defaults.
    ruby_block "radosgw-finalize-#{inst['name']}" do
      block do
        ['done', service_type].each do |ack|
          ::File.open("/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{inst['region']}-#{inst['name']}/#{ack}", 'w').close
        end
      end
      not_if "test -f /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{inst['region']}-#{inst['name']}/done"
    end
  end
end
