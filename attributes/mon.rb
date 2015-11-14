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

include_attribute 'ceph'

# The ceph mon ips attribute gets built in a wrapper recipe or chef-repo style environment like ceph-chef
default['ceph']['mon']['ips'] = nil

# init_style in each major section is allowed so that radosgw or osds or mons etc could be a different OS if required.
# The default is everything on the same OS
default['ceph']['mon']['init_style'] = node['ceph']['init_style']

default['ceph']['mon']['secret_file'] = '/etc/chef/secrets/ceph_mon'

# MUST be set in the wrapper cookbook or chef-repo like project
default['ceph']['mon']['role'] = 'search-ceph-mon'

# Default of 15 seconds but change to nil for default of .050 or set it to .050
default['ceph']['mon']['clock_drift_allowed'] = 15

case node['platform_family']
when 'debian', 'rhel', 'fedora'
  packages = ['ceph']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['mon']['packages'] = packages
else
  default['ceph']['mon']['packages'] = []
end
