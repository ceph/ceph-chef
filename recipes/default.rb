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

include_recipe 'chef-sugar::default'

include_recipe 'ceph-chef::repo' if node['ceph']['install_repo']
include_recipe 'ceph-chef::conf'

# Tools needed by cookbook
node['ceph']['packages'].each do |pck|
  package pck
end

# NOTE: The location of netaddr-1.5.1.gem is defaulted to /tmp. If one exists there then it will install that gem. If not,
# then it will install from the net. The purpose is to be able to supply all pre-reqs for those environments that
# are not allowed to access the net.

# FYI: If you're behind a firewall or no net access then you can install netaddr with the following after then node
# has been bootstrapped with Chef - /opt/chef/embedded/bin/gem install --force --local /tmp/netaddr-1.5.1.gem
# Of course, this means you have downloaded the gem from: https://rubygems.org/downloads/netaddr-1.5.1.gem and then
# copied it to your /tmp directory.
if node['ceph']['netaddr_install']
  chef_gem 'netaddr-local' do
    package_name 'netaddr'
    source '/tmp/netaddr-1.5.1.gem'
    action :install
    compile_time true
    only_if { File.exist?('/tmp/netaddr-1.5.1.gem') }
  end

  chef_gem 'netaddr' do
    action :install
    version '<2'
    compile_time true
    not_if { File.exist?('/tmp/netaddr-1.5.1.gem') }
  end
end

if node['ceph']['pools']['radosgw']['federated_enable']
  ceph_chef_build_federated_pool('radosgw')
end

execute 'ceph-systemctl-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
  only_if { systemd? }
end
