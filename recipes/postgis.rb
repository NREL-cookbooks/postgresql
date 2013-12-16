#
# Cookbook Name:: postgresql
# Recipe:: postgis
#
# Copyright 2012, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "postgresql::server"

package "postgis2_#{node['postgresql']['version'].split('.').join}" do
  # Disable rpmforge while installing postgis. Without this a newer, but
  # incompatible, version of hdf5 gets installed. We want the hdf5 library from
  # epel.
  options "--disablerepo=rpmforge"
  version node[:postgresql][:postgis_package_version]
end

prefix = "/usr/pgsql-#{node[:postgresql][:version]}"
cookbook_file "#{prefix}/share/extension/postgis_srs_esri_102003.control" do
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "#{prefix}/share/extension/postgis_srs_esri_102003--1.0.sql" do
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "#{prefix}/share/extension/postgis_srs_sr_org_6703.control" do
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "#{prefix}/share/extension/postgis_srs_sr_org_6703--1.0.sql" do
  mode "0644"
  owner "root"
  group "root"
end
