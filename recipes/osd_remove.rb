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

# This recipe will add OSDs once the physical device has been added.

if node['ceph']['osd']['remove']
  devices = node['ceph']['osd']['remove']

  devices = Hash[(0...devices.size).zip devices] unless devices.is_a? Hash

  devices.each do |_index, osd_device|
    execute "ceph-disk-zap-remove on #{osd_device['data']}" do
      command <<-EOH
        # wip - ceph-disk -v zap #{osd_device['data']} #{osd_device['journal']}
        sleep 2
      EOH
      only_if "parted --script #{osd_device['data']} print | egrep -sq '^ 1.*ceph'"
      action :run
    end
  end
else
  Log.info("node['ceph']['osd']['remove'] empty")
end
