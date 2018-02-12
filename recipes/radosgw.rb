#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook: ceph
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

node.default['ceph']['is_radosgw'] = true

include_recipe 'ceph-chef'
include_recipe 'ceph-chef::radosgw_install'

if node['ceph']['version'] == 'hammer'
  directory '/var/log/radosgw' do
    # owner node['ceph']['owner']
    # group node['ceph']['group']
    mode node['ceph']['mode']
    action :create
    not_if 'test -d /var/log/radosgw'
  end

  # If the directory does not exist already (on a dedicated node)
  directory '/var/run/ceph' do
    # owner node['ceph']['owner']
    # group node['ceph']['group']
    mode node['ceph']['mode']
    action :create
    not_if 'test -d /var/run/ceph'
  end

  # This directory is only needed if you use the bootstrap-rgw key as part of the key generation for rgw.
  # All bootstrap-xxx keys are created during the mon key creation in mon_keys.rb.
  directory '/var/lib/ceph/bootstrap-rgw' do
    owner node['ceph']['owner']
    group node['ceph']['group']
    mode node['ceph']['mode']
    action :create
    not_if 'test -d /var/lib/ceph/bootstrap-rgw'
  end
end

# IF you want specific recipes for civetweb then put them in the recipe referenced here.
include_recipe 'ceph-chef::radosgw_civetweb'

execute 'osd-create-key-mon-client-in-directory' do
  command lazy { "ceph-authtool /etc/ceph/#{node['ceph']['cluster']}.mon.keyring --create-keyring --name=mon. --add-key=#{ceph_chef_mon_secret} --cap mon 'allow *'" }
  not_if "test -s /etc/ceph/#{node['ceph']['cluster']}.mon.keyring"
end

execute 'osd-create-key-admin-client-in-directory' do
  command lazy { "ceph-authtool /etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring --create-keyring --name=client.admin --add-key=#{ceph_chef_admin_secret} --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *'" }
  not_if "test -s /etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring"
end

# Verifies or sets the correct mode only
file "/etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring" do
  mode '0640'
end

# Portion above is the same for Federated and Non-Federated versions.

if node['ceph']['pools']['radosgw']['federated_enable']
  include_recipe 'ceph-chef::radosgw_federated'
else
  include_recipe 'ceph-chef::radosgw_non_federated'
end

# TODO: This block is only here as a reminder to update the optimal PG size later...
# rgw_optimal_pg = ceph_chef_power_of_2(get_ceph_chef_osd_nodes.length*node['ceph']['pgs_per_node']/node['ceph']['rgw']['replicas']*node['ceph']['rgw']['portion']/100)

=begin
# check to see if we should up the number of pg's now for the core buckets pool
(node[['ceph']['pgp_auto_adjust'] ? %w{pg_num pgp_num} : %w{pg_num}).each do |pg|
    bash "update-rgw-buckets-#{pg}" do
        user "root"
        code "ceph osd pool set .rgw.buckets #{pg} #{rgw_optimal_pg}"
        only_if { %x[ceph osd pool get .rgw.buckets #{pg} | awk '{print $2}'].to_i < rgw_optimal_pg }
        notifies :run, "bash[wait-for-pgs-creating]", :immediately
    end
end
=end

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
#   not_if "test -s /etc/ceph/#{node['ceph']['cluster']}.client.radosgw.keyring"
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
#   not_if "test -s /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring"
#   notifies :create, 'ruby_block[save radosgw_secret]', :immediately
# end

# execute 'update rgw keys' do
#   command "ceph -k /etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring auth add client.radosgw.#{node['hostname']} -i /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring"
#   only_if {"test -s /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-#{node['hostname']}/keyring"}
# end

# execute 'set rgw_permissions' do
#   command lazy { "chmod 0644 /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring" }
#   only_if "test -s /var/lib/ceph/radosgw/#{node['ceph']['cluster']}-radosgw.#{node['hostname']}/keyring"
# end
# End of comment block

# Another way is to use the client producer. This method is less verbose but more work goes on inside the
# provider code Block. Of course, as always, a provider block is very opinionated on how things are done.
# ceph_chef_client 'radosgw' do
#   caps('mon' => 'allow rw', 'osd' => 'allow rwx')
# end

# DOCS: End
