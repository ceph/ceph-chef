#
# Author:: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook Name:: cepheus
#
# Copyright 2018, LambdaStack
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

# This recipe installs everything needed for the RGW Admin Web Service...
# NB: *IMPORTANT* - You will need to choose how to implement in your environment. Some environments
# use Apache, some use NGINX and some use something different. This process uses Python Flask.

if node['ceph']['radosgw']['rgw_webservice']['enable']
    package 'uwsgi' do
        action :upgrade
    end
    package 'uwsgi-plugin-python' do
        action :upgrade
    end
    package 'python-flask' do
        action :upgrade
    end

    directory '/usr/local/lib/rgw_webservice' do
        owner "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        mode 00755
    end

    directory '/usr/local/lib/rgw_webservice/templates' do
        owner "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        mode 00755
    end

    directory '/var/log/rgw_webservice' do
        owner "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        mode 00755
    end

    file '/usr/local/lib/rgw_webservice/__init__.py' do
        action :touch
        owner "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        mode 00644
    end

    cookbook_file '/usr/local/lib/rgw_webservice/rgw_webservice' do
        source 'rgw_webservice.py'
        owner "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        mode 00755
    end

    # NB: May want to add a config file to hold admin user and keys etc.

    # Link app to lib directory file
    link '/usr/local/bin/rgw_webservice' do
        to '/usr/local/lib/rgw_webservice/rgw_webservice.wsgi'
        user "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
    end

    # Setup the uwsgi ini
    template '/etc/rgw_webservice.ini' do
        source 'rgw-webservice.ini.erb'
        owner 'root'
        group 'root'
    end

    # Add Unit file for service
    template '/etc/systemd/system/rgw_webservice.service' do
        source 'rgw-webservice.service.erb'
        owner 'root'
        group 'root'
    end

    # Add help file
    template '/usr/local/lib/rgw_webservice/templates/rgw_webservice_help.html' do
        source 'rgw-webservice-help.html.erb'
        owner "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
        group "#{node['ceph']['radosgw']['rgw_webservice']['user']}"
    end

    # NB: So rgw_webservice process can read ceph.conf
    if node['ceph']['version'] != 'hammer'
        # Add this so that the rgw_webservice (running as radosgw) called processes (radosgw-admin) can access ceph.conf
        execute "add_radosgw_to_ceph" do
            command "usermod -a -G ceph #{node['ceph']['radosgw']['rgw_webservice']['user']}"
            ignore_failure true
        end
        # Add this so that the rgw_webservice (running as radosgw) called processes (radosgw-admin) can access ceph.conf
        execute "add_ceph_to_radosgw" do
            command "usermod -a -G #{node['ceph']['radosgw']['rgw_webservice']['user']} ceph"
            ignore_failure true
        end
    end

    # NB: This will change owner and group of radosgw-admin2 and rgw_s3_api.py that ceph-chef installed.
    execute "change_owner_group_radosgw" do
        command "chown #{node['ceph']['radosgw']['rgw_webservice']['user']}:#{node['ceph']['radosgw']['rgw_webservice']['user']} /usr/local/bin/radosgw-admin2"
    end
    execute "change_owner_group_rgw_s3_api" do
        command "chown #{node['ceph']['radosgw']['rgw_webservice']['user']}:#{node['ceph']['radosgw']['rgw_webservice']['user']} /usr/local/bin/rgw_s3_api.*"
    end
end
