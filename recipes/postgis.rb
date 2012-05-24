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

  version = "2.0.0"
  name = "postgis-#{version}"
  archive = "#{name}.tar.gz"

  node.set[:postgresql][:postgis_dir] = "#{node[:postgresql][:contrib_dir]}/postgis-2.0"

  remote_file "#{Chef::Config[:file_cache_path]}/#{archive}" do
    source "http://postgis.refractions.net/download/#{archive}"
  end

  bash "install_postgis" do
    cwd Chef::Config[:file_cache_path]

    code <<-EOS
      #export LD_LIBRARY_PATH="#{node[:gdal][:lib_path]}:#{node[:postgresql][:prefix]}/lib"
      #export PATH="#{node[:gdal][:bin_path]}:$PATH"
      echo $LD_LIBRARY_PATH
      echo $PATH

      rm -rf #{name}
      tar zxf #{archive}
      cd #{name}
      echo "=== configure... ==="
      ./configure --with-raster --without-topology
      echo "=== make... ==="
      make
      echo "=== make install... ==="
      make install
      echo "=== make comments-install... ==="
      make comments-install

      cd extensions
      cd postgis
      echo "=== extension: make clean... ==="
      make clean
      echo "=== extension: make... ==="
      make
      echo "=== extension: make install... ==="
      make install
      echo "=== extension: DONE... ==="

      cd ../..
      rm -rf #{name}
    EOS

    environment({ "LD_LIBRARY_PATH" => "#{node[:gdal][:lib_path]}:#{node[:postgresql][:prefix]}/lib", "PATH" => "#{node[:gdal][:bin_path]}:#{ENV["PATH"]}" })

    not_if do
      ::File.exists?(node[:postgresql][:postgis_dir]) && system("grep '^-- INSTALL VERSION: #{version}$' #{node[:postgresql][:postgis_dir]}/postgis.sql > /dev/null")
    end
  end
end


# INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 912003, 'esri', 102003, '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs ', 'PROJCS["USA_Contiguous_Albers_Equal_Area_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["longitude_of_center",-96],PARAMETER["Standard_Parallel_1",29.5],PARAMETER["Standard_Parallel_2",45.5],PARAMETER["latitude_of_center",37.5],UNIT["Meter",1],AUTHORITY["EPSG","102003"]]');
#
# TEST DB TOO!
