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

# TODO: Change the new two lines to ['ceph']['cephfs']['mount'] etc to be consistent
default['ceph']['cephfs_mount'] = '/ceph'
default['ceph']['cephfs_use_fuse'] = nil # whether the recipe's fuse mount uses cephfs-fuse instead of kernel client, defaults to heuristics

# MUST be set in the wrapper cookbook or chef-repo like project
default['ceph']['cephfs']['role'] = 'ceph-cephfs'

case node['platform_family']
when 'debian'
  packages = ['ceph-fs-common', 'ceph-fuse']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['cephfs']['packages'] = packages
when 'rhel', 'fedora', 'suse'
  default['ceph']['cephfs']['packages'] = ['ceph-fuse']
else
  default['ceph']['cephfs']['packages'] = []
end
