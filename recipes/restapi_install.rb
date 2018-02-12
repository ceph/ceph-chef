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

# NOTE: Additional information can be found here.
# http://ceph.com/planet/experimenting-with-the-ceph-rest-api/
#
# JSON - Add the following HTTP_HEADER: "Accept: application/json" otherwise it returns plain text.

include_recipe 'ceph-chef'

node['ceph']['restapi']['packages'].each do |pck|
  package pck
end

case node['platform_family']
when 'rhel'
  # NOTE: We will be doing a PR on the main Ceph repo soon that does the systemd config for ceph-rest-api but
  # for now, this will create the required config.
  cookbook_file '/etc/systemd/system/ceph-rest-api.service' do
    source 'ceph-rest-api.service'
    owner 'root'
    group 'root'
    mode '0644'
  end
end

include_recipe 'ceph-chef::install'
