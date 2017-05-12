#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook: ceph
# Recipe: mon_keys
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

# The name of the recipe, mon_keys, is prefixed with 'mon' so as to indicate the grouping of the recipe since it must
# be ran after mon_start.

# This recipe can only be ran AFTER a monitor has started
# NOTE: This recipe will create bootstrap keys for OSD, [MDS, RGW automatically]

# Create/save/etc the bootstrap-osd key
include_recipe 'ceph-chef::bootstrap_osd_key'

# # IF the bootstrap key for bootstrap-rgw exists then save it so it's available if wanted later. All bootstrap
# # keys are created during this recipe process!
# ruby_block 'save_bootstrap_rgw' do
#   block do
#     fetch = Mixlib::ShellOut.new("ceph-authtool '/var/lib/ceph/bootstrap-rgw/#{node['ceph']['cluster']}.keyring' --print-key --name=client.bootstrap-rgw")
#     fetch.run_command
#     key = fetch.stdout
#     ceph_chef_save_bootstrap_rgw_secret(key.delete!("\n"))
#   end
#   not_if { ceph_chef_bootstrap_rgw_secret }
#   only_if "test -s /var/lib/ceph/bootstrap-rgw/#{node['ceph']['cluster']}.keyring"
#   ignore_failure true
# end
#
# # IF the bootstrap key for bootstrap-mds exists then save it so it's available if wanted later
# ruby_block 'save_bootstrap_mds' do
#   block do
#     fetch = Mixlib::ShellOut.new("ceph-authtool '/var/lib/ceph/bootstrap-mds/#{node['ceph']['cluster']}.keyring' --print-key --name=client.bootstrap-mds")
#     fetch.run_command
#     key = fetch.stdout
#     ceph_chef_save_bootstrap_mds_secret(key.delete!("\n"))
#   end
#   not_if { ceph_chef_bootstrap_mds_secret }
#   only_if "test -s /var/lib/ceph/bootstrap-mds/#{node['ceph']['cluster']}.keyring"
#   ignore_failure true
# end
