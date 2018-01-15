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
#

require 'json'
require 'securerandom'

# NOTE: To create radosgw federated pools we need to override the default node['ceph']['pools']['radosgw']['names']
# by rebuilding the structure dynamically based on the federated options.
# name should already have '.' as first character so don't add it to formating here
def ceph_chef_build_federated_pool(pool)
  node['ceph']['pools'][pool]['federated_regions'].each do |region|
    node['ceph']['pools'][pool]['federated_zone_instances'].each do |zone_instance|
      node['ceph']['pools'][pool]['pools'].each do |pool_val|
        federated_name = ".#{region}-#{zone_instance['name']}#{pool_val['name']}"
        unless node['ceph']['pools'][pool]['federated_names'].include? federated_name
          node.default['ceph']['pools'][pool]['federated_names'] << federated_name
          node.default['ceph']['pools'][pool]['federated']['pools'] << pool_val
        end
      end
    end
  end
end

# def ceph_chef_build_federated_pool(pool)
#   node['ceph']['pools'][pool]['federated_regions'].each do |region|
#     node['ceph']['pools'][pool]['federated_zones'].each do |zone|
#       node['ceph']['pools'][pool]['federated_instances'].each do |instance|
#         node['ceph']['pools'][pool]['pools'].each do |pool_val|
#           federated_name = ".#{region}-#{zone}-#{instance['name']}#{pool_val['name']}"
#           if !node['ceph']['pools'][pool]['federated_names'].include? federated_name
#             node.default['ceph']['pools'][pool]['federated_names'] << federated_name
#             node.default['ceph']['pools'][pool]['federated']['pools'] << pool_val
#           end
#         end
#       end
#     end
#   end
# end

# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def ceph_chef_pool_create(pool)
  if !node['ceph']['pools'][pool]['federated_names'].empty? && node['ceph']['pools'][pool]['federated_names']
    node_loop = node['ceph']['pools'][pool]['federated_names']
    num_of_pool_groups = node['ceph']['pools'][pool]['federated_zone_instances'].size
    # Force it to be 1 for now since we don't know how much each federated instance will be used.
    # num_of_pool_groups = 1

    node_loop.each_with_index do |name, index|
      profile_val = nil
      options_val = nil

      pool_val =  node['ceph']['pools'][pool]['federated']['pools'][index]
      type_val = pool_val['type']
      pg_num_val = get_pool_pg_count(pool, index, type_val, num_of_pool_groups, true)
      profile_val = pool_val['profile'] if type_val == 'erasure'
      crush_ruleset_name = pool_val['crush_ruleset_name']

        if node['ceph']['pools']['version'] != 2
          ceph_chef_pool name do
            action :create
            pg_num pg_num_val
            pgp_num pg_num_val
            type type_val
            crush_ruleset pool_val['crush_ruleset'] if node['ceph']['osd']['crush']['update']
            crush_ruleset_name crush_ruleset_name if !crush_ruleset_name.nil? && node['ceph']['osd']['crush']['update']
            profile profile_val unless profile_val.nil?
            options options_val unless options_val.nil?
            # notifies :run, "bash[wait-for-pgs-creating]", :immediately
          end
        else
            profile_val = '' if profile_val.nil?
            # May want to add node['ceph']['osd']['crush']['update'] later...
            crush_ruleset_name = '' if crush_ruleset_name.nil?
            options_val = '' if options_val.nil?

            execute "ceph-pool-create-#{name}" do
              command lazy { "ceph osd pool create #{name} #{pg_num_val} #{pg_num_val} #{type_val} #{profile_val} #{crush_ruleset_name} #{options_val}" }
              not_if "ceph osd pool get #{name} pg_num"
            end
        end
    end
  else
    node_loop = node['ceph']['pools'][pool]['pools']
    node_loop.each_with_index do |pool_val, index|
      type_val = pool_val['type'] # node['ceph']['pools'][pool]['pools'][index]['type']
      pg_num_val = get_pool_pg_count(pool, index, type_val, 1, false)
      profile_val = pool_val['profile'] if type_val == 'erasure'
      crush_ruleset_name = pool_val['crush_ruleset_name']
      options_val = node['ceph']['pools'][pool]['settings']['options'] if node['ceph']['pools'][pool]['settings']['options']

      if node['ceph']['pools']['version'] != 2
          ceph_chef_pool pool_val['name'] do
            action :create
            pg_num pg_num_val
            pgp_num pg_num_val
            type type_val
            crush_ruleset pool_val['crush_ruleset'] if node['ceph']['osd']['crush']['update']
            crush_ruleset_name crush_ruleset_name if !crush_ruleset_name.nil? && node['ceph']['osd']['crush']['update']
            profile profile_val unless profile_val.nil?
            options node['ceph']['pools'][pool]['settings']['options'] if node['ceph']['pools'][pool]['settings']['options']
            # notifies :run, "bash[wait-for-pgs-creating]", :immediately
          end
      else
          profile_val = '' if profile_val.nil?
          # May want to add node['ceph']['osd']['crush']['update'] later...
          crush_ruleset_name = '' if crush_ruleset_name.nil? || !node['ceph']['osd']['crush']['update']
          options_val = '' if options_val.nil?

          execute "ceph-pool-create-#{pool_val['name']}" do
            command lazy { "ceph osd pool create #{pool_val['name']} #{pg_num_val} #{pg_num_val} #{type_val} #{profile_val} #{crush_ruleset_name} #{options_val}" }
            not_if "ceph osd pool get #{pool_val['name']} pg_num"
          end
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def ceph_chef_pool_set(pool)
  if !node['ceph']['pools'][pool]['federated_names'].empty? && node['ceph']['pools'][pool]['federated_enable']
    node_loop = node['ceph']['pools'][pool]['federated_names']
    node_loop.each do |name|
      # if node['ceph']['pools'][pool]['settings']['type'] == 'replicated'
      next unless name['type'] == 'replicated'
      val = if node['ceph']['pools'][pool]['settings']['size']
              node['ceph']['pools'][pool]['settings']['size']
            else
              node['ceph']['osd']['size']['max']
            end

      if node['ceph']['pools']['version'] != 2
          ceph_chef_pool name do
            action :set
            key 'size'
            value val
            not_if "ceph osd pool get #{name} size | grep #{val}"
          end
      else
          execute "ceph-pool-set-#{name}" do
            command lazy { "ceph osd pool set #{name} size #{val}" }
            not_if "ceph osd pool get #{name} size | grep #{val}"
          end
      end
    end
  else
    node_loop = node['ceph']['pools'][pool]['pools']
    node_loop.each do |pool_val|
      # if node['ceph']['pools'][pool]['settings']['type'] == 'replicated'
      next unless pool_val['type'] == 'replicated'
      val = if node['ceph']['pools'][pool]['settings']['size']
              node['ceph']['pools'][pool]['settings']['size']
            else
              node['ceph']['osd']['size']['max']
            end

      if node['ceph']['pools']['version'] != 2
          ceph_chef_pool pool_val['name'] do
            action :set
            key 'size'
            value val
            not_if "ceph osd pool get #{pool_val['name']} size | grep #{val}"
          end
      else
          execute "ceph-pool-set-#{pool_val['name']}" do
            command lazy { "ceph osd pool set #{pool_val['name']} size #{val}" }
            not_if "ceph osd pool get #{pool_val['name']} size | grep #{val}"
          end
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Calculate the PG count for a given pool. Set the default if count < default or error
# Reference: http://ceph.com/pgcalc/
# rubocop:disable Metrics/PerceivedComplexity
def get_pool_pg_count(pool_type, pool_index, type, num_of_pool_groups, federated)
  val = node['ceph']['pools']['pgs']['num']
  pool = if federated
           node['ceph']['pools'][pool_type]['federated']['pools'][pool_index]
         else
           node['ceph']['pools'][pool_type]['pools'][pool_index]
         end

  if pool
    calc = node['ceph']['pools']['pgs']['calc']
    total_osds = calc['total_osds']
    size = if type == 'erasure'
             calc['erasure_size']
           else
             calc['replicated_size']
           end
    size = 1 if size <= 0
    target_pgs_per_osd = calc['target_pgs_per_osd']
    data_percent = pool['data_percent']
    num_of_pool_groups = 1 if num_of_pool_groups <= 0

    # NOTE: Could add float or just make sure data_percent has decimal point in array such as 1 being 1.00 because ruby tries to be too smart.
    # NOTE: Removed - (total_osds/size)/num_of_pool_groups from array so that the PGs are not too large.
    num = [(target_pgs_per_osd * total_osds * (data_percent / 100) / num_of_pool_groups) / size, calc['min_pgs_per_pool']].max
    # The power of 2 calculation does not go to the higher but actually to the nearest power of 2 value.
    val = ceph_chef_power_of_2(num)
  end

  val
end
# rubocop:enable Metrics/PerceivedComplexity

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

def ceph_chef_is_radosgw_federated
  node['ceph']['pools']['radosgw']['federated_enable']
end

def ceph_chef_mon_env_search_string
  search_string = 'ceph_is_mon:true'
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
# NOTE: Returns nil for a reason! There is a check later in the process
# rubocop:disable Metrics/PerceivedComplexity
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
      Chef::Log.info('No fsid secret found')
      nil
    end
  elsif node['ceph']['fsid-secret']
    node['ceph']['fsid-secret']
  else
    Chef::Log.info('No fsid secret found')
    nil
  end
end
# rubocop:enable Metrics/PerceivedComplexity

def ceph_chef_save_fsid_secret(secret)
  node.normal['ceph']['fsid-secret'] = secret
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
  node.normal['ceph']['monitor-secret'] = secret
  secret
end

# Stored with Mon node always
def ceph_chef_mgr_secret
  if !ceph_chef_mon_nodes.empty?
    ceph_chef_save_mgr_secret(ceph_chef_mon_nodes[0]['ceph']['mgr-secret'])
    ceph_chef_mon_nodes[0]['ceph']['mgr-secret']
  elsif node['ceph']['mgr-secret']
    node['ceph']['mgr-secret']
  else
    Chef::Log.info('No mgr secret found')
    nil
  end
end

def ceph_chef_save_mgr_secret(secret)
  node.normal['ceph']['mgr-secret'] = secret
  secret
end

# Change ceph_chef_osd_nodes to ceph_chef_mon_nodes
# Ceph MONs set the keys so everything should pull from those and set their own node value to equal the given attribute
# Since data bags are not used, setting *ALL* mon node attributes will assure the secrets are kept even if your mon
# nodes die. If a new secret for anything is re-generated then Ceph will not work correctly.
# You can also get the secret value and store it in a data bag of the chef-repo wrapper that uses this cookbook.
def ceph_chef_bootstrap_osd_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['bootstrap-osd']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'bootstrap-osd', secret)['secret']
  elsif !ceph_chef_mon_nodes.empty?
    ceph_chef_save_bootstrap_osd_secret(ceph_chef_mon_nodes[0]['ceph']['bootstrap-osd'])
    ceph_chef_mon_nodes[0]['ceph']['bootstrap-osd']
  elsif node['ceph']['bootstrap-osd']
    node['ceph']['bootstrap-osd']
  else
    Chef::Log.info('No bootstrap-osd secret found')
    nil
  end
end

# NOTE: It's also best to store the keyring files of ceph in a neutral location so that if needed you can easily
# retrieve them.
def ceph_chef_save_bootstrap_osd_secret(secret)
  node.normal['ceph']['bootstrap-osd'] = secret
  secret
end

# Bootstrap-rgw secret check
def ceph_chef_bootstrap_rgw_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['bootstrap-rgw']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'bootstrap-rgw', secret)['secret']
  elsif !ceph_chef_mon_nodes.empty?
    ceph_chef_save_bootstrap_rgw_secret(ceph_chef_mon_nodes[0]['ceph']['bootstrap-rgw'])
    ceph_chef_mon_nodes[0]['ceph']['bootstrap-rgw']
  elsif node['ceph']['bootstrap-rgw']
    node['ceph']['bootstrap-rgw']
  else
    Chef::Log.info('No bootstrap-rgw secret found')
    nil
  end
end

# NOTE: It's also best to store the keyring files of ceph in a neutral location so that if needed you can easily
# retrieve them.
def ceph_chef_save_bootstrap_rgw_secret(secret)
  node.normal['ceph']['bootstrap-rgw'] = secret
  secret
end

# Bootstrap-mds secret check
def ceph_chef_bootstrap_mds_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['bootstrap-mds']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'bootstrap-mds', secret)['secret']
  elsif !ceph_chef_mon_nodes.empty?
    ceph_chef_save_bootstrap_mds_secret(ceph_chef_mon_nodes[0]['ceph']['bootstrap-mds'])
    ceph_chef_mon_nodes[0]['ceph']['bootstrap-mds']
  elsif node['ceph']['bootstrap-mds']
    node['ceph']['bootstrap-mds']
  else
    Chef::Log.info('No bootstrap-mds secret found')
    nil
  end
end

# NOTE: It's also best to store the keyring files of ceph in a neutral location so that if needed you can easily
# retrieve them.
def ceph_chef_save_bootstrap_mds_secret(secret)
  node.normal['ceph']['bootstrap-mds'] = secret
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
  node.normal['ceph']['admin-secret'] = secret
  secret
end

def ceph_chef_radosgw_secret
  # Return node value if it exist
  return node['ceph']['radosgw-secret'] if node['ceph']['radosgw-secret']
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['radosgw']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'radosgw', secret)['secret']
  elsif !ceph_chef_radosgw_nodes.empty?
    rgw_inst = ceph_chef_radosgw_nodes[0]
    if rgw_inst['ceph']['radosgw-secret']
      return ceph_chef_save_radosgw_secret(rgw_inst['ceph']['radosgw-secret'])
    else
      return nil
    end
  elsif node['ceph']['radosgw-secret']
    node['ceph']['radosgw-secret']
  else
    Chef::Log.info('No radosgw secret found')
    nil
  end
end

def ceph_chef_save_radosgw_secret(secret)
  node.normal['ceph']['radosgw-secret'] = secret
  node['ceph']['radosgw-secret']
end

def ceph_chef_radosgw_inst_secret(inst)
  # Return node value if exist
  if node['ceph']["radosgw-secret-#{inst}"]
    return node['ceph']["radosgw-secret-#{inst}"]
  end
  if !ceph_chef_radosgw_nodes.empty?
    # Get the first rgw nodes value
    rgw_inst = ceph_chef_radosgw_nodes[0]
    if rgw_inst['ceph']["radosgw-secret-#{inst}"]
      return ceph_chef_save_radosgw_inst_secret(rgw_inst['ceph']["radosgw-secret-#{inst}"], inst)
      # rgw_inst['ceph']["radosgw-secret-#{inst}"]
    end
  elsif node['ceph']["radosgw-secret-#{inst}"]
    node['ceph']["radosgw-secret-#{inst}"]
  else
    Chef::Log.info("No radosgw secret found for instance #{inst}")
    nil
  end
end

def ceph_chef_save_radosgw_inst_secret(secret, inst)
  node.normal['ceph']["radosgw-secret-#{inst}"] = secret
  node['ceph']["radosgw-secret-#{inst}"]
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
  node.normal['ceph']['restapi-secret'] = secret
  # ceph_chef_set_item('restapi-secret', secret)
  secret
end

# If public_network is specified with one or more networks, we need to
# search for a matching monitor IP in the node environment.
# 1. For each public network specified:
#    a. We look if the network is IPv6 or IPv4
#    b. We look for a route matching the network. You can't assume all nodes will be part of the same subnet but they
# MUST be part of the same aggregate subnet. For example, if you have 10.121.1.0/24 (class C) as your public IP block
# and all of you racks/nodes are spanning the same CIDR block then all is well. However, if you have the same public IP
# block and your racks/nodes are each routable (L3) then those racks/nodes MUST be part of the aggregate CIDR which is
# 10.121.1.0/24 in the example here. So, you could have each rack of nodes on their own subnet like /27 which will give
# you a max of 8 subnets under the aggregate of /24. For example, rack1 could be 10.121.1.0/27, rack2 - 10.121.1.32/27,
# rack3 - 10.121.1.64/27 ... up to 8 racks in this example.
#    c. If we found match, we return the IP with the port
# This function is important because we TAG nodes for specific roles and then search for those tags to dynamically
# update the node data. Of course, another way would be to create node data specific to a given role such as mon, osd ...
def ceph_chef_find_node_ip_in_network(networks, nodeish = nil)
  require 'netaddr'
  nodeish = node unless nodeish
  networks.each do |network|
    network.split(/\s*,\s*/).each do |n|
      net = NetAddr::CIDR.create(n)
      nodeish['network']['interfaces'].each do |_iface, addrs|
        addresses = addrs['addresses'] || []
        addresses.each do |ip, params|
          return ceph_chef_ip_address_to_ceph_chef_address(ip, params) if ceph_chef_ip_address_in_network?(ip, params, net)
        end
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

# To get subcidr blocks to work within a supercidr aggregate the logic has to change
# from params['prefixlen'].to_i == net.bits to removing it
def ceph_chef_ip4_address_in_network?(ip, params, net)
  net.contains?(ip) && params.key?('broadcast')
end

def ceph_chef_ip6_address_in_network?(ip, _params, net)
  net.contains?(ip) # && params['prefixlen'].to_i == net.bits
end

def ceph_chef_ip_address_to_ceph_chef_address(ip, params)
  return "#{ip}:#{node['ceph']['mon']['port']}" if params['family'].eql?('inet')
  return "[#{ip}]:#{node['ceph']['mon']['port']}" if params['family'].eql?('inet6')
end

# Find all nodes within the scope defined. For backwards-compatibility (with 0.9.x)
# this searches by tags and roles, and it is up to the user to define the roles
# in wrapper cookbooks.
# Alternately, the use of environments and existing node attributes can be used.
# Returns a list of nodes (not hostnames!)
def ceph_chef_mon_nodes
  results = nil
  if node['ceph']['search_by_environment']
    results = search(:node, ceph_chef_mon_env_search_string)
  else
    results = search(:node, "tags:#{node['ceph']['mon']['tag']}")
    if !results.include?(node) && node.run_list.roles.include?(node['ceph']['mon']['role'])
      results.push(node)
    end
  end

  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
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
  # Note: A valid cidr block MUST exist! or node['ceph']['config']['global']['public addr'] MUST be populated.
  mon_ip = ceph_chef_find_node_ip_in_network(node['ceph']['network']['public']['cidr'], nodeish) || nodeish['ceph']['config'].fetch('global', {}).fetch('public addr', nil)
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
  mon_ips = ceph_chef_mon_nodes_ip(ceph_chef_mon_nodes)
  mon_ips.reject(&:nil?).uniq
end

def ceph_chef_mon_hosts
  mon_hosts = ceph_chef_mon_nodes_host(ceph_chef_mon_nodes)
  mon_hosts.reject(&:nil?).uniq
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
  quorum_states = %w(leader peon)

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

# Nearest po2
def ceph_chef_power_of_2(number)
  result = 1
  last_pwr = 1
  while result < number
    last_pwr = result
    result <<= 1
  end

  low_delta = number - last_pwr
  high_delta = result - number
  result = last_pwr if high_delta > low_delta

  result
end

def ceph_chef_secure_password(len = 20)
  pw = ''
  pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '') while pw.length < len
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
