#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
#
# Copyright 2015, Bloomberg Finance L.P.
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

node.default['ceph']['is_radosgw'] = true

include_recipe 'ceph-chef'
include_recipe 'ceph-chef::radosgw_install'

service_type = node['ceph']['mon']['init_style']

directory '/var/log/radosgw' do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode node['ceph']['mode']
  action :create
  not_if "test -d /var/log/radosgw"
end

file "/var/log/radosgw/#{node['ceph']['cluster']}.client.radosgw.#{node['hostname']}.log" do
  owner node['ceph']['owner']
  group node['ceph']['group']
end

# If the directory does not exist already (on a dedicated node)
directory '/var/run/ceph' do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode node['ceph']['mode']
  action :create
  not_if "test -d /var/run/ceph"
end

# This directory is only needed if you use the bootstrap-rgw key as part of the key generation for rgw.
# All bootstrap-xxx keys are created during the mon key creation in mon_keys.rb.
directory '/var/lib/ceph/bootstrap-rgw' do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode node['ceph']['mode']
  action :create
  not_if "test -d /var/lib/ceph/bootstrap-rgw"
end

directory "/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}" do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode node['ceph']['mode']
  recursive true
  action :create
  not_if "test -d /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}"
end

# IF you want specific recipes for civetweb then put them in the recipe referenced here.
include_recipe "ceph-chef::radosgw_#{node['ceph']['radosgw']['webserver']}"

# NOTE: This base_key can also be the bootstrap-rgw key (ceph.keyring) if desired. Just change it here.
base_key = "/etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring"
keyring = "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"

# NOTE: If the rgw keyring exists and you are using the same key on for different nodes (load balancing) then
# this method will work well. Since the key is already part of the cluster the only thing needed is to copy it
# to the correct area (where ever the ceph.conf settings are pointing to on the given node). You can keep things
# simple by keeping the same ceph.conf the same (except for hostname info) for each rgw node.

execute 'write ceph-radosgw-secret' do
  command lazy { "ceph-authtool #{keyring} --create-keyring --name=client.radosgw.#{node['hostname']} --add-key='#{node['ceph']['radosgw-secret']}'" }
  creates keyring
  only_if { ceph_chef_radosgw_secret }
  not_if "test -f #{keyring}"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'gen client-radosgw-secret' do
  command <<-EOH
    ceph-authtool --create-keyring #{keyring} -n client.radosgw.#{node['hostname']} --gen-key --cap osd 'allow rwx' --cap mon 'allow rw'
    ceph -k #{base_key} auth add client.radosgw.#{node['hostname']} -i /etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring
  EOH
  creates keyring
  not_if { ceph_chef_radosgw_secret }
  not_if "test -f #{keyring}"
  notifies :create, 'ruby_block[save radosgw_secret]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# This ruby_block saves the key if it is needed at any other point plus this and all node data is saved on the
# Chef Server for this given node
ruby_block 'save radosgw_secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool #{keyring} --print-key")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['radosgw-secret'] = key.delete!("\n")
    node.save
  end
  action :nothing
end

# DOCS: Begin

# Create the radosgw keyring in the radosgw data directory and then copy it to /etc/ceph
# NOTE: There are multiple ways to setup keyrings. One of the simplest is as follows.
# This method works well if you combine radosgw on monitor nodes and run the recipes in one single block
# instead of based on single roles. A simple and good way. Just make sure that your not_if or only_if
# protection blocks work as intended. For example, if this is running on the first rgw node then all is
# well. However, if this runs on a second rgw node but you want the original key this will still run but
# create a new key because of the test for file existence instead of testing for saved value on the
# Chef Server.
# bash 'write-client-radosgw-key' do
#   code <<-EOH
#     ceph-authtool --create-keyring "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"
#     ceph-authtool "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring" -n "client.radosgw.#{node['hostname']}" --gen-key
#     ceph-authtool -n "client.radosgw.#{node['hostname']}" --cap osd 'allow rwx' --cap mon 'allow rw' "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"
#     ceph -k "#{base_key}" auth add client.radosgw.gateway -i "/etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"
#   EOH
#   not_if "test -f /etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"
#   notifies :create, 'ruby_block[save radosgw_secret]', :immediately
# end

# NOTE: This commented block is here to show you that there are many ways to generated keyring files and to
# illustrate they can be located anywhere you like. In this case, in /var/lib/ceph/radosgw/.../keyring
# Beginning of comment block
# bash 'write-client-radosgw-key' do
#   code <<-EOH
#     RGW_KEY=`ceph --name client.admin --keyring /etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring auth get-or-create-key client.radosgw.#{node['hostname']} osd 'allow rwx' mon 'allow rw'`
#     ceph-authtool "/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring" \
#         --create-keyring \
#         --name=client.radosgw.#{node['hostname']} \
#         --add-key="$RGW_KEY"
#   EOH
#   not_if "test -f /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring"
#   notifies :create, 'ruby_block[save radosgw_secret]', :immediately
# end

# execute 'update rgw keys' do
#   command "ceph -k /etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring auth add client.radosgw.#{node['hostname']} -i /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring"
#   only_if {"test -f /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-#{node['hostname']}/keyring"}
# end

# execute 'set rgw_permissions' do
#   command lazy { "chmod 0644 /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring" }
#   only_if "test -f /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring"
# end
# End of comment block

# Another way is to use the client producer. This method is less verbose but more work goes on inside the
# provider code Block. Of course, as always, a provider block is very opinionated on how things are done.
# ceph_chef_client 'radosgw' do
#   caps('mon' => 'allow rw', 'osd' => 'allow rwx')
# end

# DOCS: End

# TODO: This block is only here as a reminder to update the optimal PG size later...
# rgw_optimal_pg = ceph_chef_power_of_2(get_ceph_chef_osd_nodes.length*node['bcpc']['ceph']['pgs_per_node']/node['bcpc']['ceph']['rgw']['replicas']*node['bcpc']['ceph']['rgw']['portion']/100)

=begin
# check to see if we should up the number of pg's now for the core buckets pool
(node['bcpc']['ceph']['pgp_auto_adjust'] ? %w{pg_num pgp_num} : %w{pg_num}).each do |pg|
    bash "update-rgw-buckets-#{pg}" do
        user "root"
        code "ceph osd pool set .rgw.buckets #{pg} #{rgw_optimal_pg}"
        only_if { %x[ceph osd pool get .rgw.buckets #{pg} | awk '{print $2}'].to_i < rgw_optimal_pg }
        notifies :run, "bash[wait-for-pgs-creating]", :immediately
    end
end
=end

# This is only here as part of completeness. The service_type is not really needed because of defaults.
ruby_block 'radosgw-finalize' do
  block do
    ['done', service_type].each do |ack|
      ::File.open("/var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/#{ack}", 'w').close
    end
  end
end
