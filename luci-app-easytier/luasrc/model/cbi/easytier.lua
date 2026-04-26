local http = luci.http
local nixio = require "nixio"

m = Map("easytier")
m.description = translate("A simple, secure, decentralized VPN solution for intranet penetration, implemented in Rust using the Tokio framework. "
        .. "Project URL: <a href=\"https://github.com/EasyTier/EasyTier\" target=\"_blank\">github.com/EasyTier/EasyTier</a>&nbsp;&nbsp;"
        .. "<a href=\"http://easytier.cn\" target=\"_blank\">Official Documentation</a>&nbsp;&nbsp;"
        .. "<a href=\"http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=jhP2Z4UsEZ8wvfGPLrs0VwLKn_uz0Q_p&authKey=OGKSQLfg61YPCpVQuvx%2BxE7hUKBVBEVi9PljrDKbHlle6xqOXx8sOwPPTncMambK&noverify=0&group_code=949700262\" target=\"_blank\">QQ Group</a>&nbsp;&nbsp;")
  
m:section(SimpleSection).template  = "easytier/easytier_status"

s=m:section(TypedSection, "easytier", translate("EasyTier Configuration"))
s.addremove=false
s.anonymous=true
s:tab("general", translate("General Settings"))
s:tab("infos", translate("Connection Info"))
s:tab("logs", translate("Logs"))

switch = s:taboption("general",Flag, "enabled", translate("Enable"))
switch.rmempty = false

etcmd = s:taboption("general", ListValue, "etcmd", translate("Mode"))
etcmd.default = "etcmd"
etcmd:value("etcmd", translate("Default"))
etcmd:value("web", translate("Web Distribution"))

et_config = s:taboption("general", TextValue, "et_config", translate("Generate Configuration"))
et_config.rows = 18
et_config.wrap = "off"
et_config.readonly = true
et_config:depends("etcmd", "etcmd")
et_config.cfgvalue = function(self, section)
    return nixio.fs.readfile("/tmp/easytier/config.toml") or ""
end
et_config.write = function(self, section, value) end

web_config = s:taboption("general", Value, "web_config", translate("Web Server Address"),
        translate("Obtain the configuration from this address"))
web_config.placeholder = "udp://123.xyz:22020/admin"
web_config:depends("etcmd", "web")

instance_name = s:taboption("general", Value, "instance_name", translate("Instance Name"),
        translate("Distinguish Easytier node instances on the same machine"))
instance_name.placeholder = "default"
instance_name:depends("etcmd", "etcmd")

local model = nixio.fs.readfile("/proc/device-tree/model") or ""
local hostname = nixio.fs.readfile("/proc/sys/kernel/hostname") or ""
model = model:gsub("\n", "")
hostname = hostname:gsub("\n", "")
local device_name = (model ~= "" and model) or (hostname ~= "" and hostname) or "OpenWrt"
device_name = device_name:gsub(" ", "_")
hostname_opt = s:taboption("general", Value, "hostname", translate("Hostname"),
        translate("Hostname in Easytier"))
hostname_opt.placeholder = device_name

dhcp = s:taboption("general", Flag, "dhcp", translate("Enable DHCP"),
        translate("IP address will be automatically assigned by EasyTier"))
dhcp.rmempty = false
dhcp:depends("etcmd", "etcmd")

ipaddr = s:taboption("general", Value, "ipaddr", translate("Interface IP Address"),
        translate("IPv4 address of this Easytier node"))
ipaddr.datatype = "ip4addr"
ipaddr.placeholder = "10.0.0.1/24"
ipaddr:depends("etcmd", "etcmd")

ip6addr = s:taboption("general", Value, "ip6addr", translate("Interface IPV6 Address"),
        translate("IPv6 address of this Easytier node"))
ip6addr.datatype = "ip6addr"
ip6addr.placeholder = "2001:db8::1/64"
ip6addr:depends("etcmd", "etcmd")

listeners = s:taboption("general", DynamicList, "listeners", translate("Listeners"),
        translate("Listen Port setting"))
listeners.placeholder = "tcp://0.0.0.0:11010"
listeners:depends("etcmd", "etcmd")

mapped_listeners = s:taboption("general", DynamicList, "mapped_listeners", translate("Mapped Listenners"),
        translate("Inform other nodes that they can use this address to connect to this node"))
mapped_listeners.placeholder = "tcp://123.xyz:12345"
mapped_listeners:depends("etcmd", "etcmd")

proxy_cidrs = s:taboption("general", DynamicList, "proxy_cidrs", translate("Subnet Proxy"),
        translate("Inform other nodes of the local network segment"))
proxy_cidrs:depends("etcmd", "etcmd")

manual_routes = s:taboption("general", DynamicList, "manual_routes", translate("Route CIDR"),
        translate("Manually assign route CIDRs. This disables subnet proxying and WireGuard routes propagated from peer nodes"))
manual_routes.placeholder = "192.168.0.0/16"
manual_routes:depends("etcmd", "etcmd")

exit_nodes = s:taboption("general", DynamicList, "exit_nodes", translate("Exit Node Addresses"),
        translate("Forward all traffic using the node"))
exit_nodes:depends("etcmd", "etcmd")

socks = s:taboption("general", Value, "socks", translate("SOCKS5 Port"),
        translate("Create a SOCKS5 service"))
socks.datatype = "range(1,65535)"
socks.placeholder = "1080"
socks:depends("etcmd", "etcmd")

network_name = s:taboption("general", Value, "network_name", translate("Network Name"),
        translate("Used to identify this EasyTier network"))
network_name.required = true
network_name.rmempty = false
network_name.placeholder = "easytier-name"
network_name.validate = function(self, value)
    if not value or value == "" then
        return nil, translate("Network name cannot be empty")
    end
    return value
end
network_name:depends("etcmd", "etcmd")

network_secret = s:taboption("general", Value, "network_secret", translate("Network Secret"),
        translate("Used to verify whether this node belongs to the EasyTier network"))
network_secret.required = true
network_secret.rmempty = false
network_secret.placeholder = "easytier-password"
network_secret:depends("etcmd", "etcmd")

peers = s:taboption("general", DynamicList, "peers", translate("Peer Nodes"),
        translate("Initial connected peer nodes"))
peers.placeholder = "tcp://public.easytier.top:11010"
peers:depends("etcmd", "etcmd")



rpc_portal = s:taboption("general", Value, "rpc_portal", translate("Portal Address Port"),
        translate("It is recommended to use 15888 to avoid failure in obtaining status information"))
rpc_portal.placeholder = "15888"
rpc_portal.default = "15888"
rpc_portal.datatype = "range(1,65535)"
rpc_portal:depends("etcmd", "etcmd")

rpc_portal_whitelist = s:taboption("general", Value, "rpc_portal_whitelist", translate("RPC Access Whitelist"),
        translate("Only allow these addresses to access rpc portal"))
rpc_portal_whitelist.placeholder = "127.0.0.0/8,::1/128"
rpc_portal_whitelist:depends("etcmd", "etcmd")

relay_network_whitelist = s:taboption("general", Value, "relay_network_whitelist", translate("Network Relay Whitelist"),
        translate("Only allow these addresses to relay"))
relay_network_whitelist.placeholder = "10.0.0.1/24,192.168.1.0/24,fd00::/64"
relay_network_whitelist:depends("etcmd", "etcmd")

uuid = s:taboption("general", Value, "uuid", translate("UUID"),
        translate("Unique identifier used to recognize this device when connecting to the web console, for issuing configuration files"))
uuid.rows = 1
uuid.wrap = "off"
uuid:depends("etcmd", "web")
uuid.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/et_machine_id") or ""
end
uuid.write = function(self, section, value)
    nixio.fs.writefile("/etc/easytier/et_machine_id", value:gsub("\r\n", "\n"))
end


vpn_portal = s:taboption("general", Value, "vpn_portal", translate("VPN Portal URL"),
        translate("Defines the URL of the VPN portal, allowing other VPN clients to connect"))
vpn_portal.placeholder = "wg://0.0.0.0:11011/10.14.14.0/24"
vpn_portal:depends("etcmd", "etcmd")

mtu = s:taboption("general", Value, "mtu", translate("MTU"),
        translate("MTU for the TUN device, default is 1380 when unencrypted, and 1360 when encrypted"))
mtu.datatype = "range(1,1500)"
mtu.placeholder = "1300"
mtu:depends("etcmd", "etcmd")

default_protocol = s:taboption("general", ListValue, "default_protocol", translate("Default Protocol"),
        translate("The default protocol used when connecting to peer nodes"))
default_protocol:value("-")
default_protocol:value("tcp")
default_protocol:value("udp")
default_protocol:value("ws")
default_protocol:value("wss")
default_protocol:depends("etcmd", "etcmd")

dev_name = s:taboption("general", Value, "dev_name", translate("Device Name"),
        translate("Custom name for the virtual TUN interface"))
dev_name.placeholder = "easytier0"

encryption_algorithm = s:taboption("general", ListValue, "encryption_algorithm", translate("Encryption Algorithm"))
encryption_algorithm.default = "aes-gcm"
encryption_algorithm:value("xor",translate("xor"))
encryption_algorithm:value("chacha20",translate("chacha20"))
encryption_algorithm:value("aes-gcm",translate("aes-gcm"))
encryption_algorithm:value("aes-gcm-256",translate("aes-gcm-256"))
encryption_algorithm:value("openssl-aes128-gcm",translate("openssl-aes128-gcm"))
encryption_algorithm:value("openssl-aes256-gcm",translate("openssl-aes256-gcm"))
encryption_algorithm:value("openssl-chacha20",translate("openssl-chacha20"))
encryption_algorithm:depends("etcmd", "etcmd")

data_compress_algo = s:taboption("general", ListValue, "data_compress_algo", translate("Compression Algorithm"))
data_compress_algo.default = "1"
data_compress_algo:value("1",translate("none"))
-- data_compress_algo:value("1",translate("lz4"))
data_compress_algo:value("2",translate("zstd"))
data_compress_algo:depends("etcmd", "etcmd")

whitelist = s:taboption("general", DynamicList, "whitelist", translate("Whitelisted Networks"),
        translate("Only forward traffic for whitelisted networks. Input is a wildcard string"))
whitelist:depends("etcmd", "etcmd")

port_forward = s:taboption("general", DynamicList, "port_forward", translate("Port Forwarding"),
        translate("Forward a local port to a remote port within the virtual network"))
port_forward.placeholder = "udp://0.0.0.0:1234/10.0.0.1:2345"
port_forward:depends("etcmd", "etcmd")

foreign_relay_bps_limit = s:taboption("general", Value, "foreign_relay_bps_limit", translate("Forwarding Rate"),
        translate("the maximum bps limit for foreign network relay. unit: Bps (bytes per second)"))
foreign_relay_bps_limit:depends("etcmd", "etcmd")

et_flags = s:taboption("general", MultiValue, "et_flags", translate("Advance Control"))
et_flags:value("latency_first", translate("Enable Latency-First Mode")) -- 开启延迟优先
et_flags:value("use_smoltcp", translate("Use User-Space Protocol Stack")) -- 使用用户态协议栈
et_flags:value("enable_ipv6", translate("Disable IPv6")) -- 禁用IPv6
et_flags:value("enable_kcp_proxy", translate("Enable KCP Proxy")) -- 启用 KCP 代理
et_flags:value("disable_kcp_input", translate("Disable KCP Input")) -- 禁用 KCP 输入
et_flags:value("enable_quic_proxy", translate("Enable QUIC Proxy")) -- 启用 QUIC 代理
et_flags:value("disable_quic_input", translate("Disable QUIC Input")) -- 禁用 QUIC 输入
et_flags:value("disable_p2p", translate("Disable P2P")) -- 禁用 P2P
et_flags:value("p2p_only", translate("P2P Only")) -- 仅 P2P
et_flags:value("bind_device", translate("Bind to Physical Device Only")) -- 仅使用物理网卡
et_flags:value("no_tun", translate("No TUN Mode")) -- 无 TUN 模式
et_flags:value("enable_exit_node", translate("Enable Exit Node")) -- 启用出口节点
et_flags:value("relay_all_peer_rpc", translate("Relay RPC Packets")) -- 转发RPC包
et_flags:value("multi_thread", translate("Multi Thread")) -- 启用多线程
et_flags:value("proxy_forward_by_system", translate("System Forward")) -- 系统转发
et_flags:value("disable_encryption", translate("Disable Encryption")) -- 禁用加密
et_flags:value("disable_tcp_hole_punching", translate("Disable TCP Hole Punching")) -- 禁用TCP打洞
et_flags:value("disable_udp_hole_punching", translate("Disable UDP Hole Punching")) -- 禁用UDP打洞
et_flags:value("disable_sym_hole_punching", translate("Disable Symmetric NAT Hole Punching")) -- 禁用对称NAT打洞
et_flags:value("accept_dns", translate("Enable Magic DNS")) -- 启用魔法DNS
et_flags:value("private_mode", translate("Enable Private Mode")) -- 启用私有模式
et_flags.rmempty = false
et_flags:depends("etcmd", "etcmd")

multi_thread_count = s:taboption("general", Value, "multi_thread_count", translate("Number of Threads"))
multi_thread_count.placeholder = "2"
multi_thread_count.datatype = "uinteger"
multi_thread_count:depends("etcmd", "etcmd")

extra_args = s:taboption("general", Value, "extra_args", translate("Extra Parameters"))
extra_args.placeholder = "--tcp-whitelist 80 --udp-whitelist 53"
extra_args:depends("etcmd", "etcmd")

log = s:taboption("general", ListValue, "log", translate("Program Log"))
log.default = "off"
log:value("off", translate("Off"))
log:value("error", translate("Error"))
log:value("warn", translate("Warning"))
log:value("info", translate("Info"))
log:value("debug", translate("Debug"))
log:value("trace", translate("Trace"))

-- 连接信息 tab - 使用 HTM 模板展示
conninfo = s:taboption("infos", DummyValue, "_conninfo", translate("conninfo"))
conninfo.template = "easytier/easytier_conninfo"
conninfo.rawhtml = true

-- 日志tab - 使用 HTM 模板展示
logs = s:taboption("logs", DummyValue, "logs", translate("logs"))
logs.template = "easytier/easytier_log"
logs.rawhtml = true

return m

