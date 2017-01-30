#
# Cookbook Name:: ceph
# Attributes:: restapi
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

default['ceph']['restapi']['url'] = 'api.ceph.example.com'
default['ceph']['restapi']['ip'] = '10.0.100.21'
default['ceph']['restapi']['port'] = 5080
default['ceph']['restapi']['base_url'] = '/api/v0.1'
default['ceph']['restapi']['log']['level'] = 'warning'

default['ceph']['restapi']['role'] = 'search-ceph-restapi'

default['ceph']['restapi']['secret_file'] = '/etc/chef/secrets/ceph_chef_restapi'

default['ceph']['restapi']['packages'] = []
