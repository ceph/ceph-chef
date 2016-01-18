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

# NOTE: IMPORTANT: Specific attributes related to different ceph roles (i.e., mon, radosgw, osd, cephfs)
# will be found in those attribute files.

# Change this if you want a different cluster name other than the default of ceph
default['ceph']['cluster'] = 'ceph'

# This section controls which repo branch to use but is not in repo.rb because it also allows for changing of
# Ceph version information that is used for conditionals used in the recipes to KEEP them here.
default['ceph']['branch'] = 'stable' # Can be stable, testing or dev.
# Major release version to install or gitbuilder branch
default['ceph']['version'] = 'hammer'
# NOTE: If the version is greater than 'hammer' then change owner and group to 'ceph'
case default['ceph']['version']
when 'hammer'
  default['ceph']['owner'] = 'root'
  default['ceph']['group'] = 'root'
  default['ceph']['mode'] = 0755
  case node['platform']
  when 'ubuntu'
    default['ceph']['init_style'] = 'upstart'
  else
    default['ceph']['init_style'] = 'sysvinit'
  end
else
  default['ceph']['owner'] = 'ceph'
  default['ceph']['group'] = 'ceph'
  default['ceph']['mode'] = 0770
  case node['platform']
  when 'ubuntu'
    default['ceph']['init_style'] = 'upstart'
  else
    default['ceph']['init_style'] = 'systemd'
  end
end

# Override these in your environment file or here if you wish. Don't put them in the 'ceph''config''global' section.
# The public and cluster network settings are critical for proper operations.
default['ceph']['network']['public']['cidr'] = '10.0.101.0/24'
default['ceph']['network']['cluster']['cidr'] = '192.168.101.0/24'

# Will radosgw integrate with OpenStack Keystone - true/false
default['ceph']['radosgw']['keystone_auth'] = false

# Tags are used to identify nodes for searching.
# IMPORTANT
default['ceph']['admin']['tag'] = 'ceph-admin'
default['ceph']['radosgw']['tag'] = 'ceph-rgw'
default['ceph']['mon']['tag'] = 'ceph-mon'
default['ceph']['rbd']['tag'] = 'ceph-rbd'
default['ceph']['osd']['tag'] = 'ceph-osd'
default['ceph']['mds']['tag'] = 'ceph-mds'
default['ceph']['restapi']['tag'] = 'ceph-restapi'

# Set the max pid since Ceph creates a lot of threads and if using with OpenStack then...
default['ceph']['system']['pid_max'] = 4194303

default['ceph']['install_debug'] = false
default['ceph']['encrypted_data_bags'] = false

default['ceph']['install_repo'] = true
default['ceph']['btrfs'] = false

case node['platform_family']
when 'debian'
  packages = ['ceph-common', 'python-pycurl']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['packages'] = packages
when 'rhel', 'fedora'
  packages = ['ceph', 'yum-plugin-priorities.noarch', 'python-pycurl']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['packages'] = packages
else
  default['ceph']['packages'] = []
end
