default[:postgresql][:test][:config][:listen_addresses] = "localhost"
default[:postgresql][:test][:config][:port] = 5433
default[:postgresql][:test][:pg_hba] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'ident'},
  {:type => 'local', :db => 'all', :user => 'all', :addr => nil, :method => 'ident'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '::1/128', :method => 'md5'},
  {
    :comment => "# tester - all hosts",
    :type => "host",
    :db => "all",
    :user => "tester",
    :addr => "127.0.0.1/0",
    :method => "md5",
  },
]

case node['platform_family']
when 'debian'
  default[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
  default[:postgresql][:test][:config][:data_directory] = "/var/lib/postgresql/#{node[:postgresql][:version]}/main"
when 'rhel'
  if node['platform_version'].to_f >= 6.0 && node['postgresql']['version'] != '8.4'
    default[:postgresql][:test][:dir] = "/var/lib/pgsql/#{node[:postgresql][:version]}/test"
  else
    default[:postgresql][:test][:dir] = "/var/lib/pgsql/test_data"
  end
  default[:postgresql][:test][:config][:data_directory] = node[:postgresql][:test][:dir]
when 'fedora', 'suse'
  default[:postgresql][:test][:dir] = "/var/lib/pgsql/test_data"
  default[:postgresql][:test][:config][:data_directory] = node[:postgresql][:test][:dir]
else
  default[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
end
