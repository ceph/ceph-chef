#
# Author:: Chris Jones <cjones303@bloomberg.net>
# Cookbook Name:: ceph
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

# Create the admin user. These variables MUST exist for this to work. The default values can be found in
# the radosgw.rb attributes file. They can also be overridden in multiple places.
# Admin user MUST have caps set properly. Without full rights, no admin functions can occur via the admin restful calls.
ruby_block 'initialize-radosgw-admin-user' do
  block do
    rgw_admin = JSON.parse(%x[radosgw-admin user create --display-name="#{node['ceph']['radosgw']['user']['admin']['name']}" --uid="#{node['ceph']['radosgw']['user']['admin']['uid']}" --access_key="#{node['ceph']['radosgw']['user']['admin']['access_key']}" --secret="#{node['ceph']['radosgw']['user']['admin']['secret']}"])
    rgw_admin_cap = JSON.parse(%x[radosgw-admin caps add --uid="#{node['ceph']['radosgw']['user']['admin']['uid']}" --caps="users=*;buckets=*;metadata=*;usage=*;zone=*"])
  end
  not_if "radosgw-admin user info --uid='#{node['ceph']['radosgw']['user']['admin']['uid']}'"
end

# Create a test user unless you have overridden the attribute and removed the test user.
if node['ceph']['radosgw']['user']['test']['uid']
  ruby_block 'initialize-radosgw-test-user' do
    block do
      rgw_tester = JSON.parse(%x[radosgw-admin user create --display-name="#{node['ceph']['radosgw']['user']['test']['name']}" --uid="#{node['ceph']['radosgw']['user']['test']['uid']}" --max-buckets=node['ceph']['radosgw']['user']['test']['max_buckets'] --access_key="#{node['ceph']['radosgw']['user']['test']['access_key']}" --secret="#{node['ceph']['radosgw']['user']['test']['secret']}" --caps="#{node['ceph']['radosgw']['user']['test']['caps']}"])
      rgw_tester_cap = JSON.parse(%x[radosgw-admin caps add --uid="#{node['ceph']['radosgw']['user']['test']['uid']}" --caps="#{node['ceph']['radosgw']['user']['test']['caps']}"])
    end
    not_if "radosgw-admin user info --uid='#{node['ceph']['radosgw']['user']['test']['uid']}'"
  end
end
