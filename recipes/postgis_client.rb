#
# Cookbook Name:: postgresql
# Recipe:: postgis_client
#
# Copyright 2012, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "postgresql::client"

package "postgis2_#{node['postgresql']['version'].split('.').join}" do
  version node[:postgresql][:postgis_package_version]
end
