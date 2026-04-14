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
s:tab("logs", translate("logs"))

switch = s:taboption("general",Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:taboption("general", Button, "btncq", translate("Restart"))
btncq.inputtitle = translate("Restart")
btncq.description = translate("Quickly restart once without modifying any parameters")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
  luci.sys.call("rm -rf /tmp/easytier*.tag /tmp/easytier*.newtag >/dev/null 2>&1 &") -- 执行删除版本号信息
  luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &")  -- 执行重启命令
  luci.sys.call("sleep 3") -- 等3S后刷新页面
end

etcmd = s:taboption("general", ListValue, "etcmd", translate("Startup Method"))
etcmd.default = "etcmd"
etcmd:value("etcmd", translate("Default"))
etcmd:value("web", translate("Web Configuration"))

et_config = s:taboption("general", TextValue, "et_config", translate("Configuration View"))
et_config.rows = 18
et_config.wrap = "off"
et_config.readonly = true
et_config:depends("etcmd", "etcmd")
et_config.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/config.toml") or ""
end
et_config.write = function(self, section, value) end

web_config = s:taboption("general", Value, "web_config", translate("Web Server Address"),
        translate("Web configuration server address. (-w parameter)<br>"
                .. "For a self-hosted Web server, use the format: udp://server_address:22020/username<br>"
                .. "For the official Web server, use the format: username<br>"
                .. "Official Web Console: <a href='https://easytier.cn/web'>easytier.cn/web</a>"))
web_config.placeholder = "admin"
web_config:depends("etcmd", "web")

instance_name = s:taboption("general", Value, "instance_name", translate("Instance Name"),
        translate("Used to identify the VPN node instance on the same machine. (-m parameter)"))
instance_name.placeholder = "default"
instance_name:depends("etcmd", "etcmd")

local model = nixio.fs.readfile("/proc/device-tree/model") or ""
local hostname = nixio.fs.readfile("/proc/sys/kernel/hostname") or ""
model = model:gsub("\n", "")
hostname = hostname:gsub("\n", "")
local device_name = (model ~= "" and model) or (hostname ~= "" and hostname) or "OpenWrt"
device_name = device_name:gsub(" ", "_")
hostname_opt = s:taboption("general", Value, "hostname", translate("Hostname"),
        translate("The hostname used to identify this device"))
hostname_opt.placeholder = device_name

dhcp = s:taboption("general", Flag, "dhcp", translate("Enable DHCP"),
        translate("IP address will be automatically determined and assigned by EasyTier, starting from 10.0.0.1 by default. "
                .. "Warning: When using DHCP, if an IP conflict occurs in the network, the IP will be automatically changed."))
dhcp.rmempty = false
dhcp:depends("etcmd", "etcmd")

ipaddr = s:taboption("general", Value, "ipaddr", translate("Interface IP Address"),
        translate("The IPv4 address of this VPN node"))
ipaddr.datatype = "ip4addr"
ipaddr.placeholder = "10.0.0.1/24"
ipaddr:depends("dhcp", 0)

ip6addr = s:taboption("general", Value, "ip6addr", translate("Interface IPV6 Address"),
        translate("ipv6 address of this vpn node, can be used together with ipv4 for dual-stack operation"
                .. "(--ipv6 parameter)"))
ip6addr.datatype = "ip6addr"
ip6addr.placeholder = "2001:db8::1/64"
ip6addr:depends("etcmd", "etcmd")

listeners = s:taboption("general", DynamicList, "listeners", translate("Listeners"),
        translate("Listen Port setting"))
listeners.placeholder = "tcp://0.0.0.0:11010"
listeners:depends("etcmd", "etcmd")

mapped_listeners = s:taboption("general", DynamicList, "mapped_listeners", translate("Public Addresses of Specified Listeners"),
        translate("Manually specify the public IP address of this machine, so other nodes can connect to this node using "
                .. "that address (domain names not supported).<br>For example: tcp://123.123.123.123:11223, multiple entries "
                .. "can be specified"))
mapped_listeners:depends("etcmd", "etcmd")

proxy_cidrs = s:taboption("general", DynamicList, "proxy_cidrs", translate("Subnet Proxy"),
        translate("Export the local network to other peers in the VPN, allowing access to other devices in the current LAN (-n parameter)"))
proxy_cidrs:depends("etcmd", "etcmd")

manual_routes = s:taboption("general", DynamicList, "manual_routes", translate("Route CIDR"),
        translate("Manually assign route CIDRs. This disables subnet proxying and WireGuard routes propagated from peer nodes "))
manual_routes.placeholder = "192.168.0.0/16"
manual_routes:depends("etcmd", "etcmd")

exit_nodes = s:taboption("general", DynamicList, "exit_nodes", translate("Exit Node Addresses"),
        translate("Exit nodes to forward all traffic through. These are virtual IPv4 addresses. "
                .. "Priority is determined by the order in the list (--exit-nodes parameter)"))
exit_nodes:depends("etcmd", "etcmd")

socks = s:taboption("general", Value, "socks", translate("SOCKS5 Port"),
        translate("Enable a SOCKS5 server to allow SOCKS5 clients to access the virtual network. "
                .. "Leave blank to disable (--socks5 parameter)"))
socks.datatype = "range(1,65535)"
socks.placeholder = "1080"
socks:depends("etcmd", "etcmd")

network_name = s:taboption("general", Value, "network_name", translate("Network Name"),
        translate("The network name used to identify this VPN network (--network-name parameter)"))
network_name.required = true
network_name.rmempty = false
network_name.placeholder = "easytier-name"
network_name.validate = function(self, value)
    if not value or value == "" then
        return nil, translate("network_name cannot be empty")
    end
    return value
end
network_name:depends("etcmd", "etcmd")

network_secret = s:taboption("general", Value, "network_secret", translate("Network Secret"),
        translate("Network secret used to verify whether this node belongs to the VPN network (--network-secret parameter)"))
network_secret.required = true
network_secret.rmempty = false
network_secret.placeholder = "easytier-password"
network_secret:depends("etcmd", "etcmd")

peers = s:taboption("general", DynamicList, "peers", translate("Peer Nodes"),
        translate("Initial connected peer nodes (-p parameter)<br>"
                .. "Public server status check: <a href='https://uptime.easytier.cn' target='_blank'>"
                .. "Click here to check</a>"))
peers.placeholder = "tcp://public.easytier.top:11010"
peers:depends("etcmd", "etcmd")



rpc_portal = s:taboption("general", Value, "rpc_portal", translate("Portal Address Port"),
        translate("RPC portal address used for management. 0 means a random port, 12345 means listening on port 12345 on localhost, "
                .. "0.0.0.0:12345 means listening on port 12345 on all interfaces.<br>The default is 0; it is recommended to "
                .. "use 15888 to avoid failure in obtaining status information (-r parameter)"))
rpc_portal.placeholder = "15888"
rpc_portal.default = "15888"
rpc_portal.datatype = "range(1,65535)"
rpc_portal:depends("etcmd", "etcmd")

rpc_portal_whitelist = s:taboption("general", Value, "rpc_portal_whitelist", translate("RPC Access Whitelist"),
        translate("rpc portal whitelist, only allow these addresses to access rpc portal (--rpc-portal-whitelist parameter)"))
rpc_portal_whitelist.placeholder = "127.0.0.1/32,127.0.0.0/8,::1/128"
rpc_portal_whitelist:depends("etcmd", "etcmd")

relay_network_whitelist = s:taboption("general", Value, "relay_network_whitelist", translate("Network Access Whitelist"),
        translate("relay networkl whitelist, only allow these addresses to relay"))
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
        translate("Defines the URL of the VPN portal, allowing other VPN clients to connect.<br>"
                .. "Example: wg://0.0.0.0:11011/10.14.14.0/24 means the VPN portal is a WireGuard server listening on vpn."
                .. "example.com:11010, and the VPN clients are in the 10.14.14.0/24 network (--vpn-portal parameter)"))
vpn_portal.placeholder = "wg://0.0.0.0:11011/10.14.14.0/24"
vpn_portal:depends("etcmd", "etcmd")

mtu = s:taboption("general", Value, "mtu", translate("MTU"),
        translate("MTU for the TUN device, default is 1380 when unencrypted, and 1360 when encrypted"))
mtu.datatype = "range(1,1500)"
mtu.placeholder = "1300"
mtu:depends("etcmd", "etcmd")

default_protocol = s:taboption("general", ListValue, "default_protocol", translate("Default Protocol"),
        translate("The default protocol used when connecting to peer nodes (--default-protocol parameter)"))
default_protocol:value("-",translate("default"))
default_protocol:value("tcp")
default_protocol:value("udp")
default_protocol:value("ws")
default_protocol:value("wss")
default_protocol:depends("etcmd", "etcmd")

dev_name = s:taboption("general", Value, "dev_name", translate("Virtual Network Interface Name"),
        translate("Custom name for the virtual TUN interface (--dev-name parameter)<br>"
                .. "If using web configuration, please use the same virtual network interface name as in the web config for firewall allowance"))
dev_name.placeholder = "easytier0"

encryption_algorithm = s:taboption("general", ListValue, "encryption_algorithm", translate("Encryption Algorithm"),
        translate("encryption algorithm to use, supported: xor, chacha20, aes-gcm, aes-gcm-256, openssl-aes128-gcm, openssl-aes256-gcm, openssl-chacha20. default (aes-gcm) (--encryption-algorithm parameter)"))
encryption_algorithm.default = "aes-gcm"
encryption_algorithm:value("xor",translate("xor"))
encryption_algorithm:value("chacha20",translate("chacha20"))
encryption_algorithm:value("aes-gcm",translate("aes-gcm"))
encryption_algorithm:value("aes-gcm-256",translate("aes-gcm-256"))
encryption_algorithm:value("openssl-aes128-gcm",translate("openssl-aes128-gcm"))
encryption_algorithm:value("openssl-aes256-gcm",translate("openssl-aes256-gcm"))
encryption_algorithm:value("openssl-chacha20",translate("openssl-chacha20"))
encryption_algorithm:depends("etcmd", "etcmd")

data_compress_algo = s:taboption("general", ListValue, "data_compress_algo", translate("Compression Algorithm"),
        translate("Compression algorithm to use (--compression parameter)"))
data_compress_algo.default = "none"
data_compress_algo:value("1",translate("none"))
-- data_compress_algo:value("1",translate("lz4"))
data_compress_algo:value("2",translate("zstd"))
data_compress_algo:depends("etcmd", "etcmd")

whitelist = s:taboption("general", DynamicList, "whitelist", translate("Whitelisted Networks"),
        translate("Only forward traffic for whitelisted networks. Input is a wildcard string, "
                .. "e.g., '*' (all networks), 'def*' (networks prefixed with 'def')<br>Multiple networks can be specified. "
                .. "If empty, forwarding is disabled (--relay-network-whitelist parameter)"))
whitelist:depends("etcmd", "etcmd")

relay_all = s:taboption("general", Flag, "relay_all", translate("Allow Forwarding"),
        translate("Forward RPC packets from all peer nodes, even if they are not in the relay network whitelist.<br>"
                .. "This can help peer nodes in non-whitelisted networks establish P2P connections. (--relay-all-peer-rpc parameter)"))
relay_all:depends("etcmd", "etcmd")

port_forward = s:taboption("general", DynamicList, "port_forward", translate("Port Forwarding"),
        translate("Forward a local port to a remote port within the virtual network.<br>"
                .. "Example: udp://0.0.0.0:12345/10.126.126.1:23456 means forwarding local UDP port 12345 to 10.126.126.1:23456 "
                .. "in the virtual network.<br>Multiple entries can be specified. (--port-forward parameter)"))
port_forward:depends("etcmd", "etcmd")

foreign_relay_bps_limit = s:taboption("general", Value, "foreign_relay_bps_limit", translate("Forwarding Rate"),
        translate("the maximum bps limit for foreign network relay, default is no limit. unit: BPS (bytes per second). "
                .. "(--foreign-relay-bps-limit parameter)"))
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
et_flags:value("lazy_p2p", translate("Lazy P2P")) -- 延迟 P2P
et_flags:value("bind_device", translate("Bind to Physical Device Only")) -- 仅使用物理网卡
et_flags:value("no_tun", translate("No TUN Mode")) -- 无 TUN 模式
et_flags:value("enable_exit_node", translate("Enable Exit Node")) -- 启用出口节点
et_flags:value("relay_all_peer_rpc", translate("Relay RPC Packets")) -- 转发RPC包
et_flags:value("need_p2p", translate("Need P2P")) -- 需要 P2P
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

multi_thread_count = s:taboption("general", Value, "multi_thread_count", translate("Number of Threads"),
        translate("the number of threads to use, default is 2, only effective when multi-thread is enabled, must be greater than 2 (--multi-thread-count parameter)"))
multi_thread_count.placeholder = "2"
multi_thread_count.datatype = "uinteger"
-- multi_thread_count:depends(et_flags, function(v) return v and v:find("multi_thread", nil, true) end)
multi_thread_count:depends("etcmd", "etcmd")

extra_args = s:taboption("general", Value, "extra_args", translate("Extra Parameters"),
    translate("Additional command-line arguments passed to the backend process"))
extra_args.placeholder = "--tcp-whitelist 80 --udp-whitelist 53"
extra_args:depends("etcmd", "etcmd")

log = s:taboption("general", ListValue, "log", translate("Program Log"),
        translate("Runtime log is located at /tmp/easytier.log. View it in the log section above.<br>"
                .. "Levels: Error < Warning < Info < Debug < Trace"))
log.default = "off"
log:value("off", translate("Off"))
log:value("error", translate("Error"))
log:value("warn", translate("Warning"))
log:value("info", translate("Info"))
log:value("debug", translate("Debug"))
log:value("trace", translate("Trace"))

local process_status = luci.sys.exec("ps | grep easytier-core| grep -v grep")

-- 连接信息 tab - 使用 HTM 模板展示
conninfo = s:taboption("infos", DummyValue, "_conninfo")
conninfo.template = "easytier/easytier_conninfo"
conninfo.rawhtml = true

-- 日志 tab - 使用 HTM 模板展示
logs = s:taboption("logs", DummyValue, "logs", translate("logs"))
logs.template = "easytier/easytier_log"
logs.rawhtml = true

return m

