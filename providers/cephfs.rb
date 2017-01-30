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

def whyrun_supported?
  true
end

action :mount do
  converge_by("Creating cephfs mount at #{@new_resource.directory}") do
    create_mount(:mount)
  end
end

action :remount do
  converge_by("Remounting cephfs mount at #{@new_resource.directory}") do
    create_mount(:remount)
  end
end

action :umount do
  converge_by("Unmounting cephfs mount at #{@new_resource.directory}") do
    manage_mount(@new_resource.directory, @new_resource.cephfs_subdir, @new_resource.use_fuse, :umount)
  end
end

action :enable do
  converge_by("Enabling cephfs mount at #{@new_resource.directory}") do
    create_mount(:enable)
  end
end

action :disable do
  converge_by("Disabling cephfs mount at #{@new_resource.directory}") do
    manage_mount(@new_resource.directory, @new_resource.cephfs_subdir, @new_resource.use_fuse, :disable)
  end
end

def create_client
  client_name = "cephfs.#{node['hostname']}"
  filename = "/etc/ceph/ceph.client.#{client_name}.secret"

  name = 'cephfs'
  ceph_chef_client name do
    filename filename
    caps('mon' => 'allow r', 'osd' => 'allow rw', 'mds' => 'allow')
    as_keyring false
  end
end

def manage_mount(dir, subdir, use_fuse, act)
  client_name = "cephfs.#{node['hostname']}"
  filename = "/etc/ceph/ceph.client.#{client_name}.secret"

  if use_fuse
    if subdir != '/'
      Chef::Application.fatal!("Can't use a subdir with fuse mounts yet")
    end
    mount "#{act} #{dir}" do
      mount_point dir
      fstype 'fuse.ceph'
      # needs two slashes to indicate a network mount to chef
      device "conf=//etc/ceph/ceph.conf,id=#{client_name},keyfile=#{filename}"
      options 'defaults,_netdev'
      dump 0
      pass 0
      action act
    end
  else
    mons = mon_addresses.sort.join(',') + ':' + subdir
    mount "#{act} #{dir}" do
      mount_point dir
      fstype 'ceph'
      device mons
      options "_netdev,name=#{client_name},secretfile=#{filename}"
      dump 0
      pass 0
      action action
    end
  end
end

def create_mount(action)
  create_client
  directory @new_resource.directory
  manage_mount(@new_resource.directory, @new_resource.cephfs_subdir, @new_resource.use_fuse, action)
end
