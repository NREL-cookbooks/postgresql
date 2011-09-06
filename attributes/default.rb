#
# Cookbook Name:: postgresql
# Attributes:: postgresql
#
# Copyright 2008-2009, Opscode, Inc.
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

::Chef::Node.send(:include, Opscode::OpenSSL::Password)

default[:postgresql][:listen] = "localhost"
default[:postgresql][:port] = "5432"
default[:postgresql][:hba] = []

default[:postgresql][:test][:listen] = "localhost"
default[:postgresql][:test][:port] = "5433"

set_unless[:postgresql][:test][:tester_password] = secure_password
default[:postgresql][:test][:hba] = [
  {
    :comment => "tester - all hosts",
    :type => "host",
    :database => "all",
    :user => "tester",
    :address => "127.0.0.1/0",
    :method => "md5",
  },

]

case platform
when "debian"

  if platform_version.to_f == 5.0
    default[:postgresql][:version] = "8.3"
  elsif platform_version =~ /.*sid/
    default[:postgresql][:version] = "8.4"
  end

  set[:postgresql][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"
  set[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
  set[:postgresql][:contrib_dir] = "/usr/share/postgresql/#{node[:postgresql][:version]}/contrib"

when "ubuntu"

  if platform_version.to_f <= 9.04
    default[:postgresql][:version] = "8.3"
  else
    default[:postgresql][:version] = "8.4"
  end

  set[:postgresql][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"
  set[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
  set[:postgresql][:contrib_dir] = "/usr/share/postgresql/#{node[:postgresql][:version]}/contrib"

when "fedora"

  if platform_version.to_f <= 12
    default[:postgresql][:version] = "8.3"
  else
    default[:postgresql][:version] = "8.4"
  end

  set[:postgresql][:dir] = "/var/lib/pgsql/data"
  set[:postgresql][:test][:dir] = "/var/lib/pgsql/test_data"
  set[:postgresql][:contrib_dir] = "/usr/share/pgsql/contrib"

when "redhat","centos"

  default[:postgresql][:version] = "8.4"
  set[:postgresql][:dir] = "/var/lib/pgsql/data"
  set[:postgresql][:contrib_dir] = "/usr/share/pgsql/contrib"

when "suse"

  if platform_version.to_f <= 11.1
    default[:postgresql][:version] = "8.3"
  else
    default[:postgresql][:version] = "8.4"
  end

  set[:postgresql][:dir] = "/var/lib/pgsql/data"
  set[:postgresql][:test][:dir] = "/var/lib/pgsql/test_data"
  set[:postgresql][:contrib_dir] = "/usr/share/postgresql/contrib"

else
  default[:postgresql][:version] = "8.4"
  set[:postgresql][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"
  set[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
  set[:postgresql][:contrib_dir] = "/usr/share/postgresql/#{node[:postgresql][:version]}/contrib"
end
