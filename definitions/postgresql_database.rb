#
# Cookbook Name:: postgresql
# Definition:: postgresql_database
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

define :postgresql_database, :action => :create, :owner => "postgres" do
  include_recipe "postgresql::server"

  server_port = if(params[:server_port]) then "--port=#{params[:server_port]}" else "" end

  case params[:action]
  when :create
    if params[:template]
      template = "-T #{params[:template]}"
    end

    execute "createdb #{server_port} #{template} #{params[:name]}" do
      user "postgres"
      not_if "psql #{server_port} -f /dev/null #{params[:name]}", :user => "postgres"
    end

    execute "psql #{server_port} -c 'ALTER DATABASE #{params[:name]} OWNER TO #{params[:owner]}'" do
      user "postgres"
    end

    if params[:flags]
      params[:flags].each do |k,v|
        execute "psql #{server_port} -c \"UPDATE pg_catalog.pg_database SET #{k} = '#{v}' WHERE datname = '#{params[:name]}'\" #{params[:name]}" do
          user "postgres"
        end
      end
    end

    modules = params[:modules] || []
    modules = [ *modules ]
    postgis = !modules.delete("postgis").nil?

    languages = params[:languages] || []
    languages = [ *languages ]
    languages << "plpgsql" if postgis

    contrib = node.postgresql.contrib_dir

    languages.uniq.each do |language|
      execute "createlang #{server_port} #{language} #{params[:name]}" do
        user "postgres"
        not_if "psql #{server_port} -c 'SELECT lanname FROM pg_catalog.pg_language' #{params[:name]} | grep '^ #{language}$'", :user => "postgres"
      end
    end

    unless modules.empty?
      version = node.platform == "centos" ? node.postgresql.version.delete(".") : ""
      package "postgresql#{version}-contrib"
    end

    if postgis
      include_recipe "postgresql::postgis"

      if(node[:postgresql][:postgis][:v2])
        execute "psql #{server_port} -c 'CREATE EXTENSION IF NOT EXISTS postgis' #{params[:name]}" do
          user "postgres"
          environment({ "LD_LIBRARY_PATH" => "#{node[:gdal][:lib_path]}:#{node[:postgresql][:prefix]}/lib" })
        end
      else
        postgis14_sql_file = "postgis.sql"
        if(platform?("redhat", "centos", "fedora") && node[:kernel][:machine] == "x86_64")
          postgis14_sql_file = "postgis-64.sql"
        end

        # PostGIS 1.4 and above.
        execute "psql #{server_port} -1 -f #{contrib}/#{postgis14_sql_file} #{params[:name]}" do
          user "postgres"
          only_if { File.exists? "#{contrib}/#{postgis14_sql_file}" }
        end

        # PostGIS 1.3 and below.
        execute "psql #{server_port} -1 -f #{contrib}/lwpostgis.sql #{params[:name]}" do
          user "postgres"
          not_if { File.exists? "#{contrib}/#{postgis14_sql_file}" }
        end

        modules << "spatial_ref_sys"
        modules << "postgis_comments"
      end
    end

    modules.uniq.each do |mod|
      execute "psql #{server_port} -1 -f #{contrib}/#{mod}.sql #{params[:name]}" do
        user "postgres"

        # Skip postgis_comments if it's not available on the system.
        not_if do
          mod == "postgis_comments" && !File.exists?("#{contrib}/#{mod}.sql")
        end
      end
    end

    if postgis
      %w( geography_columns geometry_columns spatial_ref_sys ).each do |table|
        execute "psql #{server_port} -c 'ALTER TABLE #{table} OWNER TO #{params[:owner]}' #{params[:name]}" do
          user "postgres"
        end
      end
    end
  when :drop
    execute "psql #{server_port} -c 'DROP DATABASE IF EXISTS #{params[:name]}'" do
      user "postgres"
    end
  end
end
