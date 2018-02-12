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

# NB: Important - If the `ceph.repo` does not get created correctly then check to make sure you have set
# the node attribute for repo create to true. 

case node['platform_family']
when 'debian'
  # Debian/Ubuntu default repositories
  node.default['ceph']['debian']['stable']['repository'] = "#{node['ceph']['repo_url']}/debian-#{node['ceph']['version']}/"
  node.default['ceph']['debian']['stable']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  node.default['ceph']['debian']['testing']['repository'] = "#{node['ceph']['repo_url']}/debian-testing/"
  node.default['ceph']['debian']['testing']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  node.default['ceph']['debian']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-deb-#{node['lsb']['codename']}-x86_64-basic/ref/#{node['ceph']['version']}"
  node.default['ceph']['debian']['dev']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
when 'rhel'
  # Redhat/CentOS default repositories
  node.default['ceph']['rhel']['stable']['repository'] = "#{node['ceph']['repo_url']}/rpm-#{node['ceph']['version']}/#{node['ceph']['el_version']}/x86_64/"
  node.default['ceph']['rhel']['stable']['repository_key'] = 'file:///etc/pki/rpm-gpg/release.asc'
  # node.default['ceph']['rhel']['stable']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  node.default['ceph']['rhel']['testing']['repository'] = "#{node['ceph']['repo_url']}/rpm-testing/#{node['ceph']['el_version']}/x86_64/"
  node.default['ceph']['rhel']['testing']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
  node.default['ceph']['rhel']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-rpm-centos7.1-x86_64-basic/ref/#{node['ceph']['version']}/x86_64/"
  node.default['ceph']['rhel']['dev']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
when 'fedora'
  # Fedora default repositories
  node.default['ceph']['fedora']['stable']['repository'] = "#{node['ceph']['repo_url']}/rpm-#{node['ceph']['version']}/fc#{node['platform_version']}/x86_64/"
  node.default['ceph']['fedora']['stable']['repository_key'] = 'file:///etc/pki/rpm-gpg/release.asc'
  # node.default['ceph']['fedora']['stable']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  node.default['ceph']['fedora']['testing']['repository'] = "#{node['ceph']['repo_url']}/rpm-testing/fc#{node['platform_version']}/x86_64/"
  node.default['ceph']['fedora']['testing']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
  node.default['ceph']['fedora']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-rpm-fc#{node['platform_version']}-x86_64-basic/ref/#{node['ceph']['version']}/RPMS/x86_64/"
  node.default['ceph']['fedora']['dev']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
when 'suse'
  # (Open)SuSE default repositories
  # Chef doesn't make a difference between suse and opensuse
  suse = Mixlib::ShellOut.new("head -n1 /etc/SuSE-release| awk '{print $1}'").run_command.stdout.chomp.downcase
  suse = 'sles' if suse == 'suse'
  suse_version = suse << Mixlib::ShellOut.new("grep VERSION /etc/SuSE-release | awk -F'= ' '{print $2}'").run_command.stdout.chomp

  node.default['ceph']['suse']['stable']['repository'] = "#{node['ceph']['repo_url']}/rpm-#{node['ceph']['version']}/#{suse_version}/x86_64/ceph-release-1-0.#{suse_version}.noarch.rpm"
  node.default['ceph']['suse']['testing']['repository'] = "#{node['ceph']['repo_url']}/rpm-testing/#{suse_version}/x86_64/ceph-release-1-0.#{suse_version}.noarch.rpm"
else
  fail "#{node['platform_family']} is not supported"
end

case node['platform_family']
when 'debian'
  include_recipe 'ceph-chef::apt'
when 'rhel', 'suse', 'fedora'
  include_recipe 'ceph-chef::rpm'
else
  fail 'not supported'
end
