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

actions :mount, :umount, :remount, :enable, :disable
default_action :mount

attribute :directory, :kind_of => String, :name_attribute => true, :required => true
attribute :use_fuse, :kind_of => [TrueClass, FalseClass], :required => true, :default => true
attribute :cephfs_subdir, :kind_of => String, :default => '/'

def initialize(*args)
  super
  @action = :mount
  @run_context.include_recipe 'ceph-chef'
  @run_context.include_recipe 'ceph-chef::cephfs_install'
end
