#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
#
# Copyright 2016, Bloomberg Finance L.P.
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

platform_family = node['platform_family']

# Setup key so it doesn't have to pull it down
cookbook_file '/etc/pki/rpm-gpg/release.asc' do
  source 'release.asc'
  owner 'root'
  group 'root'
  mode '0644'
end

# case platform_family
# when 'rhel'
#   include_recipe 'yum-epel' if node['ceph']['el_add_epel']
# end

branch = node['ceph']['branch']
if branch == 'dev' && platform_family != 'centos' && platform_family != 'fedora'
  fail "Dev branch for #{platform_family} is not yet supported"
end

yum_repository 'ceph' do
  baseurl node['ceph'][platform_family][branch]['repository']
  gpgkey node['ceph'][platform_family][branch]['repository_key']
end

# Only if ceph extras repo is true
# As of CentOS and RHEL 7.x no need for ceph-extra
# yum_repository 'ceph-extra' do
#   baseurl node['ceph'][platform_family]['extras']['repository']
#   gpgkey node['ceph'][platform_family]['extras']['repository_key']
#   only_if { node['ceph']['extras_repo'] }
# end

package 'parted'    # needed by ceph-disk-prepare to run partprobe
package 'hdparm'    # used by ceph-disk activate
package 'xfsprogs'  # needed by ceph-disk-prepare to format as xfs

if node['ceph']['version'] == 'hammer'
  # 0.94.6 seemed to have a package issue where lsb-core was required and CentOS core does not install automatically
  package 'redhat-lsb-core' do # lsb-init
    not_if "test -f /lib/lsb/init-functions"
  end
end

if node['platform_family'] == 'rhel' && node['platform_version'].to_f > 6
  if node['ceph']['btrfs']
    package 'btrfs-progs' # needed to format as btrfs, (if you use it - default is false)
  end
end

if node['platform_family'] == 'rhel' && node['platform_version'].to_f < 7
  package 'python-argparse'
end
