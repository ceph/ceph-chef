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

include_recipe 'ceph-chef::mon_install'
include_recipe 'ceph-chef::mon'
include_recipe 'ceph-chef::mon_keys'
include_recipe 'ceph-chef::mon_start'
include_recipe 'ceph-chef::osd_install'
include_recipe 'ceph-chef::osd'
include_recipe 'ceph-chef::osd_start'
include_recipe 'ceph-chef::mds_install'
include_recipe 'ceph-chef::mds'
include_recipe 'ceph-chef::cephfs'
include_recipe 'ceph-chef::radosgw_install'
include_recipe 'ceph-chef::radosgw'
include_recipe 'ceph-chef::radosgw_start'
include_recipe 'ceph-chef::restapi_install'
include_recipe 'ceph-chef::restapi'
include_recipe 'ceph-chef::restapi_start'
