#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
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

# Create a new bootstrap-osd secret key if it does not exist either on disk as node attribtues
bash 'create-bootstrap-osd-key' do
  code <<-EOH
    BOOTSTRAP_KEY=$(ceph --name mon. --keyring /etc/ceph/#{node['ceph']['cluster']}.mon.keyring auth get-or-create-key client.bootstrap-osd mon 'allow profile bootstrap-osd')
    ceph-authtool "/var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring" \
        --create-keyring \
        --name=client.bootstrap-osd \
        --add-key="$BOOTSTRAP_KEY"
  EOH
  only_if "test -s /etc/ceph/#{node['ceph']['cluster']}.mon.keyring"
  not_if { ceph_chef_bootstrap_osd_secret }
  not_if "test -s /var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring"
  notifies :create, 'ruby_block[save_bootstrap_osd]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# If the bootstrap-osd secret key exists as a node attribute but not on disk, write it out
execute 'format bootstrap-osd-secret as keyring' do
  command lazy { "ceph-authtool '/var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring' --create-keyring --name=client.bootstrap-osd --add-key=#{ceph_chef_bootstrap_osd_secret}" }
  only_if { ceph_chef_bootstrap_osd_secret }
  not_if "test -s /var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

# If the bootstrap-osd secret key exists on disk but not as a node attribute, save it as an attribute
ruby_block 'check_bootstrap_osd' do
  block do
    true
  end
  notifies :create, 'ruby_block[save_bootstrap_osd]', :immediately
  not_if { ceph_chef_bootstrap_osd_secret }
  only_if "test -s /var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring"
end

# Save the bootstrap-osd secret key to the node attributes. This is typically performed
# as a notification following the create step, but you can set:
#   node['ceph']['monitor-secret'] = ceph_chef_keygen()
# in a higher level recipe to force a specific value
ruby_block 'save_bootstrap_osd' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool '/var/lib/ceph/bootstrap-osd/#{node['ceph']['cluster']}.keyring' --print-key --name=client.bootstrap-osd")
    fetch.run_command
    key = fetch.stdout
    ceph_chef_save_bootstrap_osd_secret(key.delete!("\n"))
  end
  action :nothing
end
