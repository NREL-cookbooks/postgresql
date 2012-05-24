#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Copyright 2009-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "yum::pgdg"
include_recipe "postgresql::client"

# Create a group and user like the package will.
# Otherwise the templates fail.

group "postgres" do
  # Workaround lack of option for -r and -o...
  group_name "-r -o postgres"
  not_if { Etc.getgrnam("postgres") rescue false }
  gid 26
end

user "postgres" do
  # Workaround lack of option for -M and -n...
  username "-M -n postgres"
  not_if { Etc.getpwnam("postgres") rescue false }
  shell "/bin/bash"
  comment "PostgreSQL Server"
  home "/var/lib/pgsql"
  gid "postgres"
  system true
  uid 26
  supports :non_unique => true
end

package "postgresql#{node[:postgresql][:version_no_dot]}-server"

bash "fix_9.1_init" do
  code <<-EOS
    perl -p -i -e 's#pidfile="/var/run/postmaster-9.1.pid"#pidfile="/var/run/postmaster-9.1.${PGPORT}.pid"#' /etc/rc.d/init.d/postgresql-#{node[:postgresql][:version]}
  EOS
end

template "/etc/sysconfig/pgsql/postgresql-#{node[:postgresql][:version]}" do
  source "redhat.sysconfig.erb"
  owner "root"
  group "root"
  mode "0644"
  variables node[:postgresql]
  notifies :restart, "service[postgresql]"
end

execute "/sbin/service postgresql-#{node[:postgresql][:version]} initdb" do
  not_if { ::FileTest.exist?(File.join(node[:postgresql][:dir], "PG_VERSION")) }
end

template "#{node[:postgresql][:dir]}/pg_hba.conf" do
  source "redhat.pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  variables node[:postgresql]
  notifies :reload, "service[postgresql]"
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "redhat.postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  variables node[:postgresql]
  notifies :restart, "service[postgresql]", :immediately
end

service "postgresql" do
  service_name "postgresql-#{node[:postgresql][:version]}"
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

if platform?("redhat", "centos", "scientific", "fedora")
  unless(ENV["PATH"] =~ /#{node[:postgresql][:prefix]}/)
    ENV["PATH"] = "#{node[:postgresql][:prefix]}/bin:#{ENV["PATH"]}"
    ENV["LD_LIBRARY_PATH"] = "#{node[:postgresql][:prefix]}/lib:#{ENV["LD_LIBRARY_PATH"]}"
  end

  template "/etc/profile.d/postgresql.sh" do
    source "profile.sh.erb"
    mode "0644"
    owner "root"
    group "root"
  end
end
