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

# This recipe will simply turn scrubbing off. There is another recipe that turns scrubbing on.
# NOTE: This recipe should be called before any maintenance on Ceph is performed.
# MAKE SURE to call osd_scrubbing_on recipe as soon as you can after performing the maintenance.
# If osd_scrubbing_off is off too long then a possible "scrubbing storm" may occur and impact
# performance.

execute 'ceph turn scrubbing off' do
  command <<-EOH
    ceph osd set noscrub
    ceph osd set nodeep-scrub
  EOH
end
