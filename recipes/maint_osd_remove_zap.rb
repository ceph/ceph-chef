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

# Maintenance recipe

# IMPORTANT: If your you are only wanting to remove a few OSDs from a larger cluster then bringing the 'reweight'
# down to 0 in one step should not degrade performance that much. However, if you're needing to say, swap drives out,
# then you should consider 'reweight' is small but reasonable increments until you reach 0. A good rule-of-thumb
# has been .25 increments (even smaller in some cases) to keep the degrade percentage less than 10%. You can change
# 'reweight' to a lower increment once the degrade percentage is around 1% - 2% or less. This technique can help
# save PG headaches in some environments. Of course, there are other ways to do this but this is a simple way.

# This recipe will zap all of the devices in the node['ceph']['osd']['devices'] List
# This also assumes that all needed packages were installed alread (when the OSDs were created - default)

service_type = node['ceph']['osd']['init_style']

if node['ceph']['osd']['remove']
  devices = node['ceph']['osd']['remove']

  devices = Hash[(0...devices.size).zip devices] unless devices.is_a? Hash

  include_recipe 'ceph-chef::osd_scrubbing_off'

  devices.each do |_index, osd_device|
    # Maybe put this section in provider
    execute "ceph osd out #{osd_device['device']}" do
      command lazy { "ceph osd out #{osd_device['osd']}" }
    end

    if service_type == 'upstart'
      execute 'upstart osd stop' do
        command lazy { "stop ceph-osd id=#{osd_device['osd']}" }
      end
    else
      execute 'rhel osd stop' do
        command lazy { "service ceph stop osd.#{osd_device['osd']}" }
      end
    end

    execute "ceph osd remove #{osd_device['device']}" do
      command <<-EOH
        ceph osd crush remove osd.#{osd_device['osd']}
        ceph auth del osd.#{osd_device['osd']}
        ceph osd rm #{osd_device['osd']}
      EOH
    end

    execute "unmount on #{osd_device['device']}" do
      command lazy { "umount #{osd_device['device']}#{osd_device['partition']}" }
    end

    # TODO: delete the journal partition IF the journal is on a device other than the data device (i.e., SSDs)
    # Use sgdisk -d <journal partition> /dev/<whatever device>
    if osd_device['osd'] != osd_device['journal']
      execute 'ceph journal partition delete' do
        command <<-EOH
          journal=$(/etc/ceph/scripts/ceph_journal.sh 2 #{osd_device['osd']})
          sgdisk -d $journal #{osd_device['journal']}
        EOH
      end
    end

    execute "remove mount directory - #{osd_device['device']}" do
      command lazy { "rm -rf /var/lib/ceph/osd/#{node['ceph']['cluster']}-#{osd_device['osd']}" }
      only_if "test -d /var/lib/ceph/osd/#{node['ceph']['cluster']}-#{osd_device['osd']}"
    end

    # No guard on this - zap!! The only psuedo guard is if the 'zap' attribute was missing.
    if !osd_device['zap'].nil? && osd_device['zap']
      execute "ceph-disk-zap on #{osd_device['device']}" do
        command lazy { "ceph-disk zap #{osd_device['device']}" }
      end
    end

    # If the journal is on a device other than the data device (i.e., SSDs) then removal of the partition
    # is handled earlier but letting the kernel know to update the partition table needs to be done before
    # exiting. If you don't then 'ceph-disk list' will still see the old partition but it will be
    next unless osd_device['osd'] != osd_device['journal']
    execute 'partition table kernel update' do
      command <<-EOH
          partprobe #{osd_device['journal']}
      EOH
    end
  end

  include_recipe 'ceph-chef::osd_scrubbing_on'
else
  Log.info("node['ceph']['osd']['remove'] empty")
end
