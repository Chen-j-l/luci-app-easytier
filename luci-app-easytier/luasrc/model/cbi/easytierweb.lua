local http = luci.http
local nixio = require "nixio"

m = Map("easytierweb")
m:section(SimpleSection).template  = "easytier/easytierweb_status"

s=m:section(TypedSection, "easytierweb", translate("EasyTier Web Server Configuration"))
s.addremove=false
s.anonymous=true
s:tab("general", translate("Settings"))
s:tab("logs", translate("Logs"))

enabled = s:taboption("general", Flag, "enabled", translate("Enable"))
enabled.rmempty = false

db_path = s:taboption("general", Value, "db_path", translate("Database File Path"),
        translate("Path to the sqlite3 database file used to store all data"))
db_path.default = "/etc/easytier/et.db"

web_protocol = s:taboption("general", ListValue, "web_protocol", translate("Listening Protocol"),
        translate("Distribute configuration listening protocol"))
web_protocol.default = "udp"
web_protocol:value("udp",translate("UDP"))
web_protocol:value("tcp",translate("TCP"))
web_protocol:value("ws",translate("WS"))

web_port = s:taboption("general", Value, "web_port", translate("Listening Port"),
        translate("Distribute configuration listening protocol"))
web_port.datatype = "range(1,65535)"
web_port.placeholder = "22020"
web_port.default = "22020"

api_port = s:taboption("general", Value, "api_port", translate("API Port"),
        translate("Listening port of the RESTful server, used as ApiHost by the web frontend"))
api_port.datatype = "range(1,65535)"
api_port.placeholder = "11211"
api_port.default = "11211"

html_port = s:taboption("general", Value, "html_port", translate("Web Port"),
        translate("Listening port for the web dashboard server, leave empty to disable"))
html_port.datatype = "range(1,65535)"
html_port.default = "11211"

api_host = s:taboption("general", Value, "api_host", translate("Default API Server URL"),
        translate("Show default API Server URL on Web"))

geoip_db = s:taboption("general", Value, "geoip_db", translate("GEOIP Database Path"),
        translate("External GeoIP database file path, used to locate the client"))

weblog = s:taboption("general", ListValue, "weblog", translate("Program Log"))
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
