include_recipe "postgresql::client"

package "postgis"

link "/usr/share/pgsql/contrib/postgis.sql" do
 to "/usr/share/pgsql/contrib/postgis-64.sql"
end
