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

if node['ceph']['repo']['create']
    include_recipe 'yum-epel::default'
end

platform_family = node['platform_family']

# Setup key so it doesn't have to pull it down
cookbook_file '/etc/pki/rpm-gpg/release.asc' do
  source 'release.asc'
  owner 'root'
  group 'root'
  mode '0644'
end

branch = node['ceph']['branch']
if branch == 'dev' && platform_family != 'centos' && platform_family != 'fedora'
  fail "Dev branch for #{platform_family} is not yet supported"
end

# If you use Ceph with no access to the outside world and use RHEL Satellite server then MAKE sure this value is set to false!
# Otherwise, 'ceph.repo' will be created and your install will eventually timeout with an error.
yum_repository 'ceph' do
  description "Ceph #{platform_family} #{node['ceph']['version']} #{branch}"
  baseurl node['ceph'][platform_family][branch]['repository']
  gpgkey node['ceph'][platform_family][branch]['repository_key']
  not_if 'test -s /etc/yum.repos.d/ceph.repo'
  only_if { node['ceph']['repo']['create'] }
end

package 'parted'    # needed by ceph-disk-prepare to run partprobe
package 'hdparm'    # used by ceph-disk activate
package 'xfsprogs'  # needed by ceph-disk-prepare to format as xfs

package 'redhat-lsb-core' do # lsb-init
  not_if 'test -s /lib/lsb/init-functions'
end

if node['platform_family'] == 'rhel' && node['platform_version'].to_f > 6
  if node['ceph']['btrfs']
    package 'btrfs-progs' # needed to format as btrfs, (if you use it - default is false)
  end
end

if node['platform_family'] == 'rhel' && node['platform_version'].to_f < 7
  package 'python-argparse'
end
