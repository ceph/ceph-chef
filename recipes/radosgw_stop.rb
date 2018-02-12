#
# Author:: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook Name:: ceph
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

# Stops radosgw on the given node.

service 'radosgw-stop' do
  case node['ceph']['radosgw']['init_style']
  when 'upstart'
    service_name 'radosgw-all-starter'
    provider Chef::Provider::Service::Upstart
  else
    if node['platform'] == 'debian'
      service_name 'radosgw'
    else
      if node['ceph']['version'] != 'hammer'
        service_name 'ceph-radosgw.target'
        provider Chef::Provider::Service::Systemd
      else
        service_name 'ceph-radosgw'
      end
    end
  end
  action [:stop]
end
