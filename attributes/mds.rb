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

include_attribute 'ceph-chef'

default['ceph']['mds']['init_style'] = node['init_style']

default['ceph']['mds']['secret_file'] = '/etc/chef/secrets/ceph_chef_mds'

# MUST be set in the wrapper cookbook or chef-repo like project
default['ceph']['mds']['role'] = 'search-ceph-mds'

case node['platform_family']
when 'debian'
  packages = ['ceph-mds']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['mds']['packages'] = packages
else
  default['ceph']['mds']['packages'] = []
end
