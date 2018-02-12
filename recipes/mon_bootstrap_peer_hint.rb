#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook: ceph
# Recipe: mon_start
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

# NOTE: This recipe (optional) can be used to aid in initial bootstrapping of ceph mons. Depending on how automated
# install is configured the recipe may be needed. It is not included in roles by default.

# Failure may occur when the cluster is first created because the peers may no exist yet so ignore it.
# Gets executed each time chef-client is ran which is ok
ceph_chef_mon_addresses.each do |addr|
  execute "peer #{addr}" do
    command "ceph --admin-daemon /var/run/ceph/#{node['ceph']['cluster']}-mon.#{node['hostname']}.asok add_bootstrap_peer_hint #{addr}"
    ignore_failure true
  end
end
