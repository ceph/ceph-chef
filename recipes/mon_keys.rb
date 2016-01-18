#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
# Recipe: mon_keys
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

# The name of the recipe, mon_keys, is prefixed with 'mon' so as to indicate the grouping of the recipe since it must
# be ran after mon_start.

# This recipe can only be ran AFTER a monitor has started
# NOTE: This recipe will create bootstrap keys for OSD, [MDS, RGW automatically]

execute 'format bootstrap-osd-secret as keyring' do
  command lazy { "ceph-authtool '/var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring' --create-keyring --name=client.bootstrap-osd --add-key='#{node['ceph']['bootstrap-osd']}'" }
  only_if { ceph_chef_bootstrap_osd_secret }
  not_if "test -f /var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

bash 'save-bootstrap-osd-key' do
  code <<-EOH
    BOOTSTRAP_KEY=`ceph --name mon. --keyring /etc/ceph/#{node['ceph']['cluster']}.mon.keyring auth get-or-create-key client.bootstrap-osd mon 'allow profile bootstrap-osd'`
    ceph-authtool "/var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring" \
        --create-keyring \
        --name=client.bootstrap-osd \
        --add-key="$BOOTSTRAP_KEY"
  EOH
  not_if { ceph_chef_bootstrap_osd_secret }
  not_if "test -f /var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring"
  notifies :create, 'ruby_block[save bootstrap_osd]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# Part of monitor-secret calls above - Also, you can set node['ceph']['monitor-secret'] = ceph_chef_keygen()
# in a higher level recipe like the way ceph-chef does it in ceph-mon.rb
ruby_block 'save bootstrap_osd' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool '/var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring' --print-key --name=client.bootstrap-osd")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['bootstrap-osd'] = key
    node.save
  end
  action :nothing
end

# IF the bootstrap key for bootstrap-rgw exists then save it so it's available if wanted later. All bootstrap
# keys are created during this recipe process!
ruby_block 'save bootstrap_rgw' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool '/var/lib/ceph/bootstrap-rgw/#{node['ceph']['cluster']}.keyring' --print-key --name=client.bootstrap-rgw")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['bootstrap-rgw'] = key
    node.save
  end
  ignore_failure true
end

# IF the bootstrap key for bootstrap-mds exists then save it so it's available if wanted later
ruby_block 'save bootstrap_mds' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool '/var/lib/ceph/bootstrap-mds/#{node['ceph']['cluster']}.keyring' --print-key --name=client.bootstrap-mds")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['bootstrap-mds'] = key
    node.save
  end
  ignore_failure true
end
