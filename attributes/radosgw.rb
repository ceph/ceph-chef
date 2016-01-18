#
# Cookbook Name:: ceph
# Attributes:: radosgw
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
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_attribute 'ceph-chef'

default['ceph']['radosgw']['api_fqdn'] = 'localhost'
default['ceph']['radosgw']['admin_email'] = 'admin@example.com'
default['ceph']['radosgw']['port'] = 80
default['ceph']['radosgw']['webserver'] = 'civetweb'

# OpenStack Keystone specific
default['ceph']['radosgw']['keystone_admin_token'] = nil
default['ceph']['radosgw']['keystone_url'] = nil
default['ceph']['radosgw']['keystone_url_port'] = 35358

default['ceph']['radosgw']['dns_name'] = nil

# Number of RADOS handles RGW has access to - system default = 1
default['ceph']['radosgw']['rgw_num_rados_handles'] = 5

# init_style in each major section is allowed so that radosgw or osds or mons etc could be a different OS if required.
# The default is everything on the same OS
default['ceph']['radosgw']['init_style'] = node['ceph']['init_style']

# An admin user needs to be added to RGW. Feel free to change as you see fit or leave it.
# Important: These values must be present or the creation of the admin user will fail!
default['ceph']['radosgw']['user']['admin']['uid'] = 'radosgw'
default['ceph']['radosgw']['user']['admin']['name'] = 'Admin'
default['ceph']['radosgw']['user']['admin']['access_key'] = ceph_chef_secure_password_alphanum_upper(20)
default['ceph']['radosgw']['user']['admin']['secret'] = ceph_chef_secure_password(40)

# Test user: If you don't want one then set the next line to = ''
default['ceph']['radosgw']['user']['test']['uid'] = 'tester'
default['ceph']['radosgw']['user']['test']['name'] = 'Tester'
default['ceph']['radosgw']['user']['test']['access_key'] = ceph_chef_secure_password_alphanum_upper(20)
default['ceph']['radosgw']['user']['test']['secret'] = ceph_chef_secure_password(40)
default['ceph']['radosgw']['user']['test']['max_buckets'] = 3
default['ceph']['radosgw']['user']['test']['caps'] = 'usage=read; user=read; bucket=*'

default['ceph']['radosgw']['secret_file'] = '/etc/chef/secrets/ceph_chef_rgw'

# MUST be set in the wrapper cookbook or chef-repo like project
default['ceph']['radosgw']['role'] = 'search-ceph-radosgw'

case node['platform_family']
when 'debian'
  packages = ['radosgw', 'radosgw-agent', 'python-boto']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['radosgw']['packages'] = packages
when 'rhel', 'fedora', 'suse'
  default['ceph']['radosgw']['packages'] = ['ceph-radosgw', 'mailcap', 'python-boto'] # NOTE: mailcap should have been a dependency in Ceph. radosgw-agent later
else
  default['ceph']['radosgw']['packages'] = []
end
