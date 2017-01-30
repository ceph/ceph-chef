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

actions :add
default_action :add

attribute :name, :kind_of => String, :name_attribute => true
attribute :caps, :kind_of => Hash, :default => { 'mon' => 'allow r', 'osd' => 'allow r' }

# Whether to store the secret in a keyring file or a plain secret file
attribute :as_keyring, :kind_of => [TrueClass, FalseClass], :default => true

# what the key should be called in the ceph cluster
# defaults to client.#{name}.#{hostname}
attribute :keyname, :kind_of => String

# The actual key (a random key will be generated if not provided)
attribute :key, :kind_of => String, :default => nil

# where the key should be saved
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.keyring if as_keyring
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.secret if not as_keyring
attribute :filename, :kind_of => String

# key file access creds
attribute :owner, :kind_of => String, :default => 'root'
attribute :group, :kind_of => String, :default => 'root'
attribute :mode, :kind_of => [Integer, String], :default => '00644'

attr_accessor :exists, :caps_match, :keys_match
