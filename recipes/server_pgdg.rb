#
# Cookbook Name:: postgresql
# Recipe:: server_pgdg
#
# Copyright 2012, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "yum::pgdg"
include_recipe "postgresql::client"

# Create a group and user like the package will.
# Otherwise the templates fail.

group "postgres" do
  gid 26
end

user "postgres" do
  shell "/bin/bash"
  comment "PostgreSQL Server"
  home "/var/lib/pgsql"
  gid "postgres"
  system true
  uid 26
  supports :manage_home => false
end

package "postgresql#{node[:postgresql][:version_no_dot]}-server"

template "/etc/sysconfig/pgsql/postgresql-#{node[:postgresql][:version]}" do
  source "redhat.sysconfig.erb"
  owner "root"
  group "root"
  mode "0644"
  variables node[:postgresql]
  notifies :restart, "service[postgresql]"
end

execute "/sbin/service postgresql-#{node[:postgresql][:version]} initdb" do
  not_if { ::FileTest.exist?(File.join(node.postgresql.dir, "PG_VERSION")) }
end

service "postgresql" do
  service_name "postgresql-#{node[:postgresql][:version]}"
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "redhat.postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  variables node[:postgresql]
  notifies :restart, resources(:service => "postgresql")
end

prefix = "/usr/pgsql-#{node[:postgresql][:version]}"

unless(ENV["PATH"] =~ /#{prefix}/)
  ENV["PATH"] = "#{prefix}/bin:#{ENV["PATH"]}"
  ENV["LD_LIBRARY_PATH"] = "#{prefix}/lib:#{ENV["LD_LIBRARY_PATH"]}"
end

template "/etc/profile.d/postgresql.sh" do
  source "profile.sh.erb"
  mode "0644"
  owner "root"
  group "root"
  variables :prefix => prefix
end
