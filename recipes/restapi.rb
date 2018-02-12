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

node.default['ceph']['is_rest_api'] = true

include_recipe 'ceph-chef'

service_type = node['ceph']['mon']['init_style']

# if node['ceph']['version'] == 'hammer'
directory "/var/lib/ceph/restapi/#{node['ceph']['cluster']}-restapi" do
    owner node['ceph']['owner']
    group node['ceph']['group']
    mode 0755
    recursive true
    action :create
    not_if "test -d /var/lib/ceph/restapi/#{node['ceph']['cluster']}-restapi"
end
# end

base_key = "/etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring"
keyring = "/etc/ceph/#{node['ceph']['cluster']}.client.restapi.keyring"

# NOTE: If the restapi keyring exists and you are using the same key on for different nodes (load balancing) then
# this method will work well. Since the key is already part of the cluster the only thing needed is to copy it
# to the correct area (where ever the ceph.conf settings are pointing to on the given node). You can keep things
# simple by keeping the same ceph.conf the same (except for hostname info) for each restapi node.
execute 'write ceph-restapi-secret' do
  command lazy { "ceph-authtool #{keyring} --create-keyring --name=client.restapi --add-key='#{node['ceph']['restapi-secret']}'" }
  only_if { ceph_chef_restapi_secret }
  not_if "test -s #{keyring}"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# command lazy { "ceph-authtool --create-keyring #{keyring} -n client.restapi.#{node['hostname']} --gen-key --cap osd 'allow *' --cap mon 'allow *'" }
execute 'gen client-restapi-secret' do
  command lazy { "ceph auth get-or-create client.restapi osd 'allow *' mon 'allow *' -o #{keyring}" }
  creates keyring
  not_if { ceph_chef_restapi_secret }
  not_if "test -s #{keyring}"
  notifies :create, 'ruby_block[save restapi_secret]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# This ruby_block saves the key if it is needed at any other point plus this and all node data is saved on the
# Chef Server for this given node
ruby_block 'save restapi_secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool /etc/ceph/#{node['ceph']['cluster']}.client.restapi.keyring --print-key")
    fetch.run_command
    key = fetch.stdout
    # ceph_chef_set_item('restapi-secret', key.delete!("\n"))
    node.normal['ceph']['restapi-secret'] = key.delete!("\n")
    # node.save
  end
  action :nothing
end

# This is only here as part of completeness.
ruby_block 'restapi-finalize' do
  block do
    ['done', service_type].each do |ack|
      ::File.open("/var/lib/ceph/restapi/#{node['ceph']['cluster']}-restapi/#{ack}", 'w').close
    end
  end
  not_if "test -f /var/lib/ceph/restapi/#{node['ceph']['cluster']}-restapi/done"
end
