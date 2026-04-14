local http = luci.http
local nixio = require "nixio"

m = Map("easytierweb")
m:section(SimpleSection).template  = "easytier/easytierweb_status"

s=m:section(TypedSection, "easytierweb", translate("EasyTier Web Server Configuration"))
s.addremove=false
s.anonymous=true
s:tab("general", translate("Settings"))
s:tab("logs", translate("logs"))

enabled = s:taboption("general", Flag, "enabled", translate("Enable"))
enabled.rmempty = false

btncq = s:taboption("general", Button, "btncq", translate("Restart"))
btncq.inputtitle = translate("Restart")
btncq.description = translate("Quickly restart once without modifying any parameters")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
  luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &")  -- 执行重启命令
end

db_path = s:taboption("general", Value, "db_path", translate("Database File Path"),
        translate("Path to the sqlite3 database file used to store all data. (-d parameter)"))
db_path.default = "/etc/easytier/et.db"

web_protocol = s:taboption("general", ListValue, "web_protocol", translate("Listening Protocol"),
        translate("Configure the server's listening protocol for easytier-core to connect. (-p parameter)"))
web_protocol.default = "udp"
web_protocol:value("udp",translate("UDP"))
web_protocol:value("tcp",translate("TCP"))
web_protocol:value("ws",translate("WS"))

web_port = s:taboption("general", Value, "web_port", translate("Server Port"),
        translate("Configure the server's listening port for easytier-core to connect. (-c parameter)"))
web_port.datatype = "range(1,65535)"
web_port.placeholder = "22020"
web_port.default = "22020"

api_port = s:taboption("general", Value, "api_port", translate("API Port"),
        translate("Listening port of the RESTful server, used as ApiHost by the web frontend. (-a parameter)"))
api_port.datatype = "range(1,65535)"
api_port.placeholder = "11211"
api_port.default = "11211"

html_port = s:taboption("general", Value, "html_port", translate("Web Interface Port"),
        translate("Frontend listening port for the web dashboard server. Leave empty to disable. (-l parameter)"))
html_port.datatype = "range(1,65535)"
html_port.default = "11211"

api_host = s:taboption("general", Value, "api_host", translate("Default API Server URL"),
        translate("The URL of the API server, used for connecting the web frontend. (--api-host parameter)<br>"
                .. "Example: http://[current device IP or resolved domain name]:[API port]"))

geoip_db = s:taboption("general", Value, "geoip_db", translate("GEOIP_DB Path"),
        translate("GeoIP2 database file path used to locate the client. Defaults to an embedded file (country-level information only)."
		.. "<br>Recommended: https://github.com/P3TERX/GeoLite.mmdb (--geoip-db parameter)"))
geoip_db.placeholder = "/etc/easytier/GeoLite.mmdb"

weblog = s:taboption("general", ListValue, "weblog", translate("Program Log"),
        translate("Runtime log located at /tmp/easytierweb.log, viewable in the log section above.<br>"
                .. "Levels: Error < Warning < Info < Debug < Trace"))
weblog.default = "off"
weblog:value("off", translate("Off"))
weblog:value("error", translate("Error"))
weblog:value("warn", translate("Warning"))
weblog:value("info", translate("Info"))
weblog:value("debug", translate("Debug"))
weblog:value("trace", translate("Trace"))

-- 日志 tab - 使用 HTM 模板展示
logs = s:taboption("logs", DummyValue, "logs", translate("logs"))
logs.template = "easytier/easytierweb_log"
logs.rawhtml = true

return m
