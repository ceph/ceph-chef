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

# IMPORTANT: Use this recipe *ONLY* if you just want to add OSD devices and *NOT* have them included as part of the
# actual ['ceph']['osd']['devices'] array. *IF* you want to add the devices on a more permanent basis then *ADD* the
# given device to the ['ceph']['osd']['devices'] array and call *OSD.rb* recipe instead!

# TODO: Add an osd provider that creates an osd, removes an osd and starts/stops an osd.
# It can also reweight an osd so as to bring down a number of them gracefully so that they
# can be safely removed instead of just stopping the osd and removing from the crush map.

if node['ceph']['osd']['add']
  devices = node['ceph']['osd']['add']

  devices = Hash[(0...devices.size).zip devices] unless devices.is_a? Hash

  devices.each do |index, osd_device|
    partitions = 1

    unless osd_device['status'].nil? || osd_device['status'] != 'deployed'
      Log.info("osd: osd device '#{osd_device}' has already been setup.")
      next
    end

    # if the 'encrypted' attribute is true then apply flag. This will encrypt the data at rest.
    # IMPORTANT: More work needs to be done on solid key management for very high security environments.
    dmcrypt = osd_device['encrypted'] == true ? '--dmcrypt' : ''

    # is_device - Is the device a partition or not
    # is_ceph - Does the device contain the default 'ceph data' or 'ceph journal' label
    # The -v option is added to the ceph-disk script so as to get a verbose output if debugging is needed. No other reason.
    # is_ceph=$(parted --script #{osd_device['data']} print | egrep -sq '^ 1.*ceph')
    execute "ceph-disk-prepare on #{osd_device['data']}" do
      command <<-EOH
        is_device=$(echo '#{osd_device['data']}' | egrep '/dev/(([a-z]{3,4}[0-9]$)|(cciss/c[0-9]{1}d[0-9]{1}p[0-9]$))')
        ceph-disk -v prepare --cluster #{node['ceph']['cluster']} #{dmcrypt} --fs-type #{node['ceph']['osd']['fs_type']} #{osd_device['data']} #{osd_device['journal']}
        if [[ ! -z $is_device ]]; then
          ceph-disk -v activate #{osd_device['data']}#{partitions}
        else
          ceph-disk -v activate #{osd_device['data']}
        fi
        sleep 3
      EOH
      # NOTE: The meaning of the uuids used here are listed above
      not_if "sgdisk -i1 #{osd_device['data']} | grep -i 4fbd7e29-9d25-41b8-afd0-062c0ceff05d" unless dmcrypt
      not_if "sgdisk -i1 #{osd_device['data']} | grep -i 4fbd7e29-9d25-41b8-afd0-5ec00ceff05d" if dmcrypt
      # Only if there is no 'ceph *' found in the label. The recipe os_remove_zap should be called to remove/zap
      # all devices if you are wanting to add all of the devices again (if this is not the initial setup)
      only_if "parted --script #{osd_device['data']} print | egrep -sq '^ 1.*ceph'"
      action :run
      notifies :create, "ruby_block[save osd_device status #{index}]", :immediately
    end

    # Add this status to the node env so that we can implement recreate and/or delete functionalities in the future.
    ruby_block "save osd_device status #{index}" do
      block do
        node.normal['ceph']['osd']['devices'][index]['status'] = 'deployed'
        # node.save
      end
      action :nothing
    end
  end
else
  Log.info("node['ceph']['osd']['add'] empty")
end
