#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
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

include_attribute 'ceph-chef'

# NOTE: This is already created so don't try to set it again.
default['ceph']['erasure_code']['profile'] = 'default'
default['ceph']['erasure_code']['directory'] = '/usr/lib/ceph/erasure-code'
# There may be more but at the initial time of this code the following are valid plugins:
# jerasure (default), SHEC, isa, lrc
# You can check the following docs http://docs.ceph.com/docs/master/rados/operations/erasure-code-profile/
default['ceph']['erasure_code']['plugin'] = 'SHEC'
# If you want to override settings of an existing profile then set this value to true (default is false)
default['ceph']['erasure_code']['force'] = true

# NOTE: Each plugin has it's own set of unique parameters so handle this use the following hash variable
# to add the unique values. For example, {"k" => 8, "m" => 3}
default['ceph']['erasure_code']['key_value'] = {"k" => 8, "m" => 3}
