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

include_recipe 'ceph-chef::install'

directory '/var/run/ceph/guests/' do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode  node['ceph']['mode']
end

directory '/var/lib/qemu' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

# libvirtd...
# directory "/var/log/qemu/" do
#   owner "libvirt-qemu"
#   group "libvirtd"
#   mode  "0755"
# end
