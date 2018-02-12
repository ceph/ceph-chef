#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook: ceph
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

provides :ceph_chef_pool

def whyrun_supported?
  true
end

use_inline_resources

action :create do
  if @current_resource.exists
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  else
    converge_by("Creating #{@new_resource}") do
      create_pool
      set_pool_crush_ruleset if @new_resource.crush_ruleset >= 0
    end
  end
end

# Note: Set only checks for existing resourse and not if the pool is set to the value passed so it will
# always run in a chef-client run.
action :set do
  if !@current_resource.exists
    Chef::Log.info "#{@new_resource} does not exist - can't update anything."
  else
    converge_by("Updating #{@new_resource}") do
      set_pool
    end
  end
end

action :get do
  converge_by("Getting #{@new_resource}") do
    get_pool
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Deleting #{@new_resource}") do
      delete_pool
    end
  else
    Chef::Log.info "#{@current_resource} does not exist - nothing to do."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephChefPool.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = pool_exists?(@current_resource.name)
end

# profile is only used for erasure coding...
def create_pool
  cmd_text = "ceph osd pool create #{new_resource.name} #{new_resource.pg_num} #{new_resource.pgp_num} #{new_resource.type}"
  cmd_text << " #{new_resource.profile}" if new_resource.profile
  cmd_text << " #{new_resource.crush_ruleset_name}" if new_resource.crush_ruleset_name
  cmd_text << " #{new_resource.options}" if new_resource.options

  puts "\nRunning... #{cmd_text}"

  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool created: #{cmd.stderr}"
end

def set_pool
  cmd_text = "ceph osd pool set #{new_resource.name} #{new_resource.key} #{new_resource.value}"

  puts "\nSetting... #{cmd_text}"

  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool updated: #{cmd.stderr}"
end

def set_pool_crush_ruleset
  cmd_text = "ceph osd pool set #{new_resource.name} crush_ruleset #{new_resource.crush_ruleset}"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool crush_ruleset updated: #{cmd.stderr}"
end

# rubocop:disable Style/AccessorMethodName
def get_pool
  cmd = shell_out("ceph osd pool get #{new_resource.name} #{new_resource.key}")
  cmd.stdout
end
# rubocop:enable Style/AccessorMethodName

def delete_pool
  cmd_text = "ceph osd pool delete #{new_resource.name}"
  cmd_text << " #{new_resource.name} --yes-i-really-really-mean-it"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool deleted: #{cmd.stderr}"
end

def pool_exists?(name)
  cmd = Mixlib::ShellOut.new("ceph osd pool get #{name} size")
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool exists: #{cmd.stdout}"
  true
rescue
  Chef::Log.debug "Pool doesn't seem to exist: #{cmd.stderr}"
  false
end

#
