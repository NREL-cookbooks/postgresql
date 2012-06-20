include_recipe "yum::pgdg"

package "postgresql#{node[:postgresql][:version_no_dot]}-devel"
