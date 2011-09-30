#
# Cookbook Name:: postgresql
# Attributes:: test_server
#
# Copyright 2011, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "iptables::postgresql_test"
include_recipe "postgresql::server"

link "/etc/init.d/postgresql-test" do
  to "/etc/init.d/postgresql"
end

template "/etc/sysconfig/pgsql/postgresql-test" do
  source "redhat.sysconfig.erb"
  owner "root"
  group "root"
  mode "0644"
  variables node[:postgresql][:test]
  notifies :restart, "service[postgresql-test]"
end

execute "/sbin/service postgresql-test initdb" do
  not_if { ::FileTest.exist?(File.join(node[:postgresql][:test][:dir], "PG_VERSION")) }
end

template "#{node[:postgresql][:test][:dir]}/pg_hba.conf" do
  source "redhat.pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  variables node[:postgresql][:test]
  notifies :reload, "service[postgresql-test]"
end

template "#{node[:postgresql][:test][:dir]}/postgresql.conf" do
  source "redhat.postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  variables node[:postgresql][:test]
  notifies :restart, "service[postgresql-test]"
end

service "postgresql-test" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

postgresql_user "tester" do
  password node[:postgresql][:test][:tester_password]
  server_port node[:postgresql][:test][:port]
  privileges :superuser => true
end
