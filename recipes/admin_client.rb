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

keyring = "/etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring"

# This will execute on other nodes besides the first mon node.
execute 'format ceph-admin-secret as keyring' do
  command lazy { "ceph-authtool --create-keyring #{keyring} --name=client.admin --add-key='#{node['ceph']['admin-secret']}' --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *'" }
  creates keyring
  only_if { ceph_chef_admin_secret }
  not_if "test -f #{keyring}"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'gen ceph-admin-secret' do
  command lazy { "ceph-authtool --create-keyring #{keyring} --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *'" }
  creates keyring
  not_if { ceph_chef_admin_secret }
  not_if "test -f #{keyring}"
  notifies :create, 'ruby_block[save ceph_chef_admin_secret]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

ruby_block 'save ceph_chef_admin_secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool #{keyring} --print-key")
    fetch.run_command
    key = fetch.stdout
    puts key
    node.set['ceph']['admin-secret'] = key
    node.save
  end
  action :nothing
end

execute 'set permissions' do
  command lazy { "chmod 0644 /etc/ceph/#{node['ceph']['cluster']}.client.admin.keyring" }
  only_if "test -f #{keyring}"
end
