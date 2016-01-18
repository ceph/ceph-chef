#
# Author:: Chris Jones <cjones303@bloomberg.net>
# Cookbook Name:: ceph
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

require 'json'

def ceph_chef_is_mon_node
  val = false
  nodes = ceph_chef_mon_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_is_osd_node
  val = false
  nodes = ceph_chef_osd_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_is_radosgw_node
  val = false
  nodes = ceph_chef_radosgw_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_is_restapi_node
  val = false
  nodes = ceph_chef_restapi_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_is_rbd_node
  val = false
  nodes = ceph_chef_rbd_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_is_admin_node
  val = false
  nodes = ceph_chef_admin_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_is_mds_node
  val = false
  nodes = ceph_chef_mds_nodes
  nodes.each do |n|
    if n['hostname'] == node['hostname']
      val = true
      break
    end
  end
  val
end

def ceph_chef_mon_env_search_string
  search_string = 'ceph_chef_is_mon:true'
  if node['ceph']['search_environment'].is_a?(String)
    # search for nodes with this particular env
    search_string += " AND chef_environment:#{node['ceph']['search_environment']}"
  elsif node['ceph']['search_environment']
    # search for any nodes with this environment
    search_string += " AND chef_environment:#{node.chef_environment}"
  end
  search_string
end

# fsid is on all nodes so just use a function similar to ceph_chef_mon_secret
def ceph_chef_fsid_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['fsid']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'fsid', secret)['secret']
  elsif !ceph_chef_mon_nodes.empty?
    secret = ceph_chef_mon_nodes[0]['ceph']['fsid-secret']
    if !secret.nil? && !secret.empty?
      ceph_chef_save_fsid_secret(secret)
      ceph_chef_mon_nodes[0]['ceph']['fsid-secret']
    elsif node['ceph']['fsid-secret']
      node['ceph']['fsid-secret']
    else
      nil
    end
  else
    Chef::Log.info('No fsid secret found')
    nil
  end
end

def ceph_chef_save_fsid_secret(secret)
  node.set['ceph']['fsid-secret'] = secret
  node.save
  secret
end

def ceph_chef_mon_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['mon']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'mon', secret)['secret']
  elsif !ceph_chef_mon_nodes.empty?
    ceph_chef_save_mon_secret(ceph_chef_mon_nodes[0]['ceph']['monitor-secret'])
    ceph_chef_mon_nodes[0]['ceph']['monitor-secret']
  elsif node['ceph']['monitor-secret']
    node['ceph']['monitor-secret']
  else
    Chef::Log.info('No monitor secret found')
    nil
  end
end

def ceph_chef_save_mon_secret(secret)
  node.set['ceph']['monitor-secret'] = secret
  node.save
  secret
end

def ceph_chef_bootstrap_osd_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['bootstrap-osd']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'bootstrap_osd', secret)['secret']
  elsif !ceph_chef_osd_nodes.empty?
    ceph_chef_save_bootstrap_osd_secret(ceph_chef_osd_nodes[0]['ceph']['bootstrap-osd'])
    ceph_chef_osd_nodes[0]['ceph']['bootstrap-osd']
  elsif node['ceph']['bootstrap-osd']
    node['ceph']['bootstrap-osd']
  else
    Chef::Log.info('No bootstrap-osd secret found')
    nil
  end
end

def ceph_chef_save_bootstrap_osd_secret(secret)
  node.set['ceph']['bootstrap-osd'] = secret
  node.save
  secret
end

def ceph_chef_admin_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['admin']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'admin', secret)['secret']
  elsif !ceph_chef_admin_nodes.empty?
    ceph_chef_save_admin_secret(ceph_chef_admin_nodes[0]['ceph']['admin-secret'])
    ceph_chef_admin_nodes[0]['ceph']['admin-secret']
  elsif node['ceph']['admin-secret']
    node['ceph']['admin-secret']
  else
    Chef::Log.info('No admin secret found')
    nil
  end
end

def ceph_chef_save_admin_secret(secret)
  node.set['ceph']['admin-secret'] = secret
  node.save
  secret
end

def ceph_chef_radosgw_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['radosgw']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'radowgw', secret)['secret']
  elsif !ceph_chef_radosgw_nodes.empty?
    ceph_chef_save_radosgw_secret(ceph_chef_radosgw_nodes[0]['ceph']['radosgw-secret'])
    ceph_chef_radosgw_nodes[0]['ceph']['radosgw-secret']
  elsif node['ceph']['radosgw-secret']
    node['ceph']['radosgw-secret']
  else
    Chef::Log.info('No radosgw secret found')
    nil
  end
end

def ceph_chef_save_radosgw_secret(secret)
  node.set['ceph']['radosgw-secret'] = secret
  node.save
  secret
end

def ceph_chef_restapi_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['restapi']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'restapi', secret)['secret']
  elsif !ceph_chef_restapi_nodes.empty?
    ceph_chef_save_restapi_secret(ceph_chef_restapi_nodes[0]['ceph']['restapi-secret'])
    ceph_chef_restapi_nodes[0]['ceph']['restapi-secret']
  elsif node['ceph']['restapi-secret']
    node['ceph']['restapi-secret']
  else
    Chef::Log.info('No restapi secret found')
    nil
  end
end

def ceph_chef_save_restapi_secret(secret)
  node.set['ceph']['restapi-secret'] = secret
  node.save
  secret
end

# If public_network is specified with one or more networks, we need to
# search for a matching monitor IP in the node environment.
# 1. For each public network specified:
#    a. We look if the network is IPv6 or IPv4
#    b. We look for a route matching the network
#    c. If we found match, we return the IP with the port
def ceph_chef_find_node_ip_in_network(network, nodeish = nil)
  require 'netaddr'
  nodeish = node unless nodeish
  network.split(/\s*,\s*/).each do |n|
    net = NetAddr::CIDR.create(n)
    nodeish['network']['interfaces'].each do |_iface, addrs|
      addresses = addrs['addresses'] || []
      addresses.each do |ip, params|
        return ceph_chef_ip_address_to_ceph_chef_address(ip, params) if ceph_chef_ip_address_in_network?(ip, params, net)
      end
    end
  end
  nil
end

def ceph_chef_ip_address_in_network?(ip, params, net)
  # Find the IP on this interface that matches the public_network
  # Uses a few heuristics to find the primary IP that ceph would bind to
  # Most secondary IPs never have a broadcast value set
  # Other secondary IPs have a prefix of /32
  # Match the prefix that we want from the public_network prefix
  if params['family'] == 'inet' && net.version == 4
    ceph_chef_ip4_address_in_network?(ip, params, net)
  elsif params['family'] == 'inet6' && net.version == 6
    ceph_chef_ip6_address_in_network?(ip, params, net)
  else
    false
  end
end

def ceph_chef_ip4_address_in_network?(ip, params, net)
  net.contains?(ip) && params.key?('broadcast') && params['prefixlen'].to_i == net.bits
end

def ceph_chef_ip6_address_in_network?(ip, params, net)
  net.contains?(ip) && params['prefixlen'].to_i == net.bits
end

def ceph_chef_ip_address_to_ceph_chef_address(ip, params)
  if params['family'].eql?('inet')
    return "#{ip}:6789"
  elsif params['family'].eql?('inet6')
    return "[#{ip}]:6789"
  end
end

# For this function to work, this cookbook will need to be part of a wrapper or project that implements ceph-mon role
# Returns a list of nodes (not hostnames!)
def ceph_chef_mon_nodes
  results = search(:node, "tags:#{node['ceph']['mon']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['mon']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def ceph_chef_osd_nodes
  results = search(:node, "tags:#{node['ceph']['osd']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['osd']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def ceph_chef_radosgw_nodes
  results = search(:node, "tags:#{node['ceph']['radosgw']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['radosgw']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def ceph_chef_restapi_nodes
  results = search(:node, "tags:#{node['ceph']['restapi']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['restapi']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def ceph_chef_rbd_nodes
  results = search(:node, "tags:#{node['ceph']['rbd']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['rbd']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def ceph_chef_admin_nodes
  results = search(:node, "tags:#{node['ceph']['admin']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['admin']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def ceph_chef_mds_nodes
  results = search(:node, "tags:#{node['ceph']['mds']['tag']}")
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  if !results.include?(node) && node.run_list.roles.include?(node['ceph']['mds']['role'])
    results.push(node)
  end
  results.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

# ex. ceph_chef_get_mon_nodes_ip(ceph_chef_get_mon_nodes)
def ceph_chef_mon_nodes_ip(nodes)
  mon_ips = []
  nodes.each do |nodish|
    mon_ips.push(ceph_chef_mon_node_ip(nodish))
  end
  mon_ips
end

def ceph_chef_mon_node_ip(nodeish)
  # Note: A valid cidr block MUST exist!
  mon_ip = ceph_chef_find_node_ip_in_network(node['ceph']['network']['public']['cidr'], nodeish)
  mon_ip
end

def ceph_chef_mon_nodes_host(nodes)
  mon_hosts = []
  nodes.each do |nodish|
    mon_hosts.push(nodish['hostname'])
  end
  mon_hosts
end

# Returns a list of ip:port of ceph mon for public network
def ceph_chef_mon_addresses
  # if File.exist?("/var/run/ceph/#{node['ceph']['cluster']}-mon.#{node['hostname']}.asok")
  #   mon_ips = ceph_chef_quorum_members_ips
  # else
  #   if node['ceph']['mon']['ips']
  #     mon_ips = node['ceph']['mon']['ips']
  #   else
  mon_ips = ceph_chef_mon_nodes_ip(ceph_chef_mon_nodes)
  #   end
  # end
  mon_ips.reject { |m| m.nil? }.uniq
end

def ceph_chef_mon_hosts
  mon_hosts = ceph_chef_mon_nodes_host(ceph_chef_mon_nodes)
  mon_hosts.reject { |m| m.nil? }.uniq
end

def ceph_chef_quorum_members_ips
  cmd = Mixlib::ShellOut.new("ceph --admin-daemon /var/run/ceph/#{node['ceph']['cluster']}-mon.#{node['hostname']}.asok mon_status")
  cmd.run_command
  cmd.error!

  mon_ips = []
  mons = JSON.parse(cmd.stdout)['monmap']['mons']
  mons.each do |k|
    mon_ips.push(k['addr'][0..-3])
  end
  mon_ips
end

def ceph_chef_quorum?
  # "ceph auth get-or-create-key" would hang if the monitor wasn't
  # in quorum yet, which is highly likely on the first run. This
  # helper lets us delay the key generation into the next
  # chef-client run, instead of hanging.
  #
  # Also, as the UNIX domain socket connection has no timeout logic
  # in the ceph tool, this exits immediately if the ceph-mon is not
  # running for any reason; trying to connect via TCP/IP would wait
  # for a relatively long timeout.
  quorum_states = %w(leader, peon)

  cmd = Mixlib::ShellOut.new("ceph --admin-daemon /var/run/ceph/#{node['ceph']['cluster']}-mon.#{node['hostname']}.asok mon_status")
  cmd.run_command
  cmd.error!

  state = JSON.parse(cmd.stdout)['state']
  quorum_states.include?(state)
end

# Cephx is on by default, but users can disable it.
# type can be one of 3 values: cluster, service, or client.  If the value is none of the above, set it to cluster
def ceph_chef_ceph_chef_use_cephx?(type = nil)
  # Verify type is valid
  type = 'cluster' if %w(cluster service client).index(type).nil?

  # CephX is enabled if it's not configured at all, or explicity enabled
  node['ceph']['config'].nil? ||
    node['ceph']['config']['global'].nil? ||
    node['ceph']['config']['global']["auth #{type} required"].nil? ||
    node['ceph']['config']['global']["auth #{type} required"] == 'cephx'
end

def ceph_chef_power_of_2(number)
  result = 1
  while result < number
    result <<= 1
  end
  result
end

def ceph_chef_secure_password(len = 20)
  pw = ''
  while pw.length < len
    pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
  end
  pw
end

def ceph_chef_secure_password_alphanum_upper(len = 20)
  # Chef's syntax checker doesn't like multiple exploders in same line. Sigh.
  alphanum_upper = [*'0'..'9']
  alphanum_upper += [*'A'..'Z']
  # We could probably optimize this to be in one pass if we could easily
  # handle the case where random_bytes doesn't return a rejected char.
  raw_pw = ''
  while raw_pw.length < len
    raw_pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
  end
  pw = ''
  while pw.length < len
    pw << alphanum_upper[raw_pw.bytes.to_a[pw.length] % alphanum_upper.length]
  end
  pw
end
