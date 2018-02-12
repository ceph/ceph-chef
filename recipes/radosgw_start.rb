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

service 'radosgw-start' do
  case node['ceph']['radosgw']['init_style']
  when 'upstart'
    service_name 'radosgw-all-starter'
    provider Chef::Provider::Service::Upstart
  else
    if node['platform'] == 'debian'
      service_name 'radosgw'
    else
      if node['ceph']['version'] != 'hammer'
        # May want to do it another way - 'ceph-radosgw@radosgw.gateway' <-- Name of the service in ceph.conf
        #  ('client.radosgw.gateway') less 'client' part based on stock unit file
        # NB: Can supply your own unit file that allows for more custom radosgw naming.
        service_name 'ceph-radosgw@radosgw.gateway'
        provider Chef::Provider::Service::Systemd
      else
        service_name 'ceph-radosgw'
      end
    end
  end
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
end
