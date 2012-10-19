#
# Cookbook Name:: postgresql
# Recipe:: postgis
#
# Copyright 2012, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "postgresql::server"

package "postgis2_#{node[:postgresql][:version_no_dot]}"

=begin
postgresql_database "template_postgis" do
  connection :host => "localhost", :port => node[:postgresql][:port]
  owner "postgres"
end

postgis_init_sql = <<-EOS
  CREATE EXTENSION IF NOT EXISTS postgis;
  DO $$
    BEGIN
      IF NOT EXISTS(SELECT srid FROM spatial_ref_sys WHERE srid = 912003) THEN
        INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 999003, 'esri', 102003, '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs ', 'PROJCS["USA_Contiguous_Albers_Equal_Area_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["longitude_of_center",-96],PARAMETER["Standard_Parallel_1",29.5],PARAMETER["Standard_Parallel_2",45.5],PARAMETER["latitude_of_center",37.5],UNIT["Meter",1],AUTHORITY["EPSG","102003"]]');
      END IF;
    END
  $$;
EOS

postgresql_database "template_postgis" do
  connection :host => "localhost", :port => node[:postgresql][:port]
  sql postgis_init_sql
  action :query
end

if(node[:recipes].include?("postgresql::test_server") || node.recipe?("postgresql::test_server"))
  postgresql_database "template_postgis" do
    connection :host => "localhost", :port => node[:postgresql][:test][:port], :password => node[:postgresql][:test][:password][:postgres]
    owner "postgres"
  end

  postgresql_database "template_postgis" do
    connection :host => "localhost", :port => node[:postgresql][:test][:port], :password => node[:postgresql][:test][:password][:postgres]
    sql postgis_init_sql
    action :query
  end
end
=end
