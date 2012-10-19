default[:postgresql][:test][:listen] = "localhost"
default[:postgresql][:test][:port] = "5433"
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
when "debian", "ubuntu"
  set[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
when "fedora", "redhat", "centos", "scientific", "amazon", "suse"
  set[:postgresql][:test][:dir] = "/var/lib/pgsql/test_data"
else
  set[:postgresql][:test][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/test"
end
