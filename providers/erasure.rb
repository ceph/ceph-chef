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

provides :ceph_chef_erasure

def whyrun_supported?
  true
end

use_inline_resources

action :set do
  converge_by("Creating #{@new_resource}") do
    set_profile
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Deleting #{@new_resource}") do
      delete_profile
    end
  else
    Chef::Log.info "#{@current_resource} does not exist - nothing to do."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephChefErasure.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = profile_exists?(@current_resource.name)
end

# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def set_profile
  if @current_resource.exists && !new_resource.force
    Chef::Log.debug 'Erasure profile exists and force not issued.'
    return 1
  end

  cmd_text = "ceph osd erasure-code-profile set #{new_resource.name}"
  unless new_resource.directory.nil?
    cmd_text += " directory=#{new_resource.directory}"
  end

  cmd_text += " plugin=#{new_resource.plugin}" unless new_resource.plugin.nil?

  unless new_resource.technique.nil?
    cmd_text += " technique=#{new_resource.technique}"
  end

  if !new_resource.ruleset_root.nil? && !new_resource.ruleset_root.empty?
    cmd_text += " ruleset-root=#{new_resource.ruleset_root}"
  end

  if !new_resource.ruleset_failure_domain.nil? && !new_resource.ruleset_failure_domain.empty?
    cmd_text += " ruleset-failure-domain=#{new_resource.ruleset_failure_domain}"
  end

  #  if !new_resource.packet_size.nil?
  #    cmd_text += " packet-size=#{new_resource.packet_size}"
  #  end

  unless new_resource.key_value.nil?
    new_resource.key_value.each do |key, value|
      cmd_text += " #{key}=#{value}"
    end
  end

  cmd_text += ' --force' if new_resource.force

  puts "\nErasure-coding profile... #{cmd_text}"

  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Erasure coding profile updated: #{cmd.stderr}"
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

def delete_profile
  cmd_text = "ceph osd erasure-code-profile rm #{new_resource.name}"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Erasure coding profile deleted: #{cmd.stderr}"
end

def profile_exists?(name)
  cmd = Mixlib::ShellOut.new("ceph osd erasure-code-profile get #{name}")
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Erasure coding profile exists: #{cmd.stdout}"
  true
rescue
  Chef::Log.debug "Erasure coding profile doesn't seem to exist: #{cmd.stderr}"
  false
end
