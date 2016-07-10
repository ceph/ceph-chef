#
# Author:: Chris Jones <cjones303@bloomberg.net>
# Cookbook Name:: ceph
#
# Copyright 2016, Bloomberg Finance L.P.
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

# Default NON-Federated version of creating keys and setting up radosgw.

# NOTE: This recipe *MUST* be included in the 'radosgw' recipe and not used as a stand alone recipe!

service_type = node['ceph']['mon']['init_style']

# NOTE: This base_key can also be the bootstrap-rgw key (ceph.keyring) if desired but the default is the admin key. Just change it here.
base_key = "/etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring"
keyring = "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"

Chef::Log.info "RADOSGW - NON-Federated Version..."

file "/var/log/radosgw/#{node['ceph']['cluster']}.client.radosgw.log" do
  owner node['ceph']['owner']
  group node['ceph']['group']
end

directory "/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.gateway" do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode node['ceph']['mode']
  recursive true
  action :create
  not_if "test -d /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.gateway"
end

new_key = ''
# Make sure the key is saved if part of ceph auth list
ruby_block 'check-radosgw-secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph auth get-key client.radosgw.gateway")
    fetch.run_command
    key = fetch.stdout
    new_key = key
    ceph_chef_save_radosgw_secret(key.delete!("\n"))
  end
end

# If a key exists then this will run
if !new_key
  new_key = ceph_chef_radosgw_secret
end
execute 'write-ceph-radosgw-secret' do
  command lazy { "ceph-authtool #{keyring} --create-keyring --name=client.radosgw.gateway --add-key=#{new_key}" }
  only_if { new_key }
  not_if "test -f #{keyring}"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# If no key exists then this will run
execute 'generate-client-radosgw-secret' do
  command <<-EOH
    ceph-authtool --create-keyring #{keyring} -n client.radosgw.gateway --gen-key --cap osd 'allow rwx' --cap mon 'allow rwx'
  EOH
  creates keyring
  not_if { ceph_chef_radosgw_secret }
  not_if "test -f #{keyring}"
  notifies :create, 'ruby_block[save-radosgw-secret]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'add-radosgw-secret' do
  command <<-EOH
    ceph -k #{base_key} auth add client.radosgw.gateway -i /etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring
  EOH
  not_if "sudo grep client.radosgw.gateway #{keyring}"
  notifies :create, 'ruby_block[save-radosgw-secret]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# Saves the key to the current node attribute
ruby_block 'save-radosgw-secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool #{keyring} --print-key")
    fetch.run_command
    key = fetch.stdout
    ceph_chef_save_radosgw_secret(key.delete!("\n"))
  end
  action :nothing
end

# This is only here as part of completeness. The service_type is not really needed because of defaults.
ruby_block 'radosgw-finalize' do
  block do
    ['done', service_type].each do |ack|
      ::File.open("/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.gateway/#{ack}", 'w').close
    end
  end
  not_if "test -f /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.gateway/done"
end
