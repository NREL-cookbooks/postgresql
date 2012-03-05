#
# Cookbook Name:: postgresql
# Recipe:: postgis
#
# Copyright 2010, FindsYou Limited
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

include_recipe "postgresql::server"

if(!node[:postgresql][:postgis][:v2])
  node.set[:postgresql][:postgis_dir] = node[:postgresql][:contrib_dir]

  if platform?("redhat", "centos", "scientific", "fedora")
    package "postgis#{node[:postgresql][:version_no_dot]}"
  elsif platform?("debian", "ubuntu")
    package "postgresql-#{node.postgresql.version}-postgis"
  else
    package "postgis"
  end
else
  include_recipe "build-essential"
  include_recipe "gdal"

  package "geos-devel"

  version = "2.0.0beta2SVN"
  name = "postgis-#{version}"
  archive = "#{name}.tar.gz"

  node.set[:postgresql][:postgis_dir] = "#{node[:postgresql][:contrib_dir]}/postgis-2.0"

  remote_file "#{Chef::Config[:file_cache_path]}/#{archive}" do
    source "http://postgis.refractions.net/download/#{archive}"
  end

  bash "install_postgis" do
    cwd Chef::Config[:file_cache_path]

    code <<-EOS
      tar zxf #{archive}
      cd #{name}
      ./configure --with-raster --without-topology
      make
      make install
      make comments-install

      cd extensions
      cd postgis
      make clean
      make
      make install

      cd ../..
      rm -rf #{name}
    EOS

    not_if do
      ::File.exists?(node[:postgresql][:postgis_dir]) && system("grep '^-- INSTALL VERSION: #{version}$' #{node[:postgresql][:postgis_dir]}/postgis.sql > /dev/null")
    end
  end
end
