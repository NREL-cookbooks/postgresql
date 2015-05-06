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
include_recipe "database::postgresql"

# randomly generate postgres password
node.set_unless[:postgresql][:test][:password][:postgres] = secure_password
node.set_unless[:postgresql][:test][:password][:tester] = secure_password
node.save unless Chef::Config[:solo]

# Fix to allow the default init script to by symlinked to support multiple
# instances of postgres.
bash "fix_9.1_init" do
  code <<-EOS
    perl -p -i -e 's#/var/run/postmaster-9.1.pid#/var/run/postmaster-9.1.\\${PGPORT}.pid#' /etc/rc.d/init.d/postgresql-#{node[:postgresql][:version]}
  EOS
  only_if "cat /etc/rc.d/init.d/postgresql-#{node[:postgresql][:version]} | grep '/var/run/postmaster-9\.1\.pid'"
end

link "/etc/init.d/postgresql-#{node[:postgresql][:version]}-test" do
  to "/etc/init.d/postgresql-#{node[:postgresql][:version]}"
end

config = node[:postgresql][:config].merge(node[:postgresql][:test][:config])

template "/etc/sysconfig/pgsql/#{node['postgresql']['server']['service_name']}-test" do
  source "pgsql.sysconfig.erb"
  mode "0644"
  variables(:dir => node[:postgresql][:test][:dir], :config => config, :svc_name => "#{node['postgresql']['server']['service_name']}-test")
  notifies :restart, "service[postgresql]", :delayed
end

execute "/sbin/service postgresql-#{node[:postgresql][:version]}-test initdb" do
  not_if { ::FileTest.exist?(File.join(node[:postgresql][:test][:dir], "PG_VERSION")) }
end

service "postgresql-test" do
  service_name "#{node['postgresql']['server']['service_name']}-test"
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

template "#{node[:postgresql][:test][:dir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  variables(:config => config)
  notifies :reload, 'service[postgresql-test]', :immediately
end

template "#{node[:postgresql][:test][:dir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 00600
  variables(:pg_hba => node[:postgresql][:test][:pg_hba])
  notifies :reload, 'service[postgresql-test]', :immediately
end

# Default PostgreSQL install has 'ident' checking on unix user 'postgres'
# and 'md5' password checking with connections from 'localhost'. This script
# runs as user 'postgres', so we can execute the 'role' and 'database' resources
# as 'root' later on, passing the below credentials in the PG client.
bash "assign-postgres-test-password" do
  user 'postgres'
  code <<-EOH
echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{node[:postgresql][:test][:password][:postgres]}';" | psql -p #{config[:port]}
  EOH
  not_if do
    begin
      require 'rubygems'
      Gem.clear_paths
      require 'pg'
      conn = PGconn.connect("localhost", config[:port], nil, nil, nil, "postgres", node['postgresql']['test']['password']['postgres'])
    rescue PGError
      false
    end
  end
  action :run
end

postgresql_database_user "tester" do
  connection :host => "localhost", :port => config[:port], :password => node[:postgresql][:test][:password][:postgres]
  password node[:postgresql][:test][:password][:tester]
end

postgresql_database "template1" do
  connection :host => "localhost", :port => config[:port], :password => node[:postgresql][:test][:password][:postgres]
  sql "ALTER ROLE tester WITH SUPERUSER"
  action :query
end
