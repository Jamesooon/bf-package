local ipkg = require('luci.model.ipkg')

local kernel_version = luci.sys.exec("echo -n $(uname -r)")

m = Map("turboacc")
m.title	= translate("Turbo ACC Acceleration Settings")
m.description = translate("Opensource Flow Offloading driver (Fast Path or Hardware NAT)")

m:append(Template("turboacc/status"))

s = m:section(TypedSection, "turboacc", "")
s.addremove = false
s.anonymous = true

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/xt_FLOWOFFLOAD.ko") then
sw_flow = s:option(Flag, "sw_flow", translate("Software flow offloading"))
sw_flow.default = 0
sw_flow.description = translate("Software based offloading for routing/NAT")
sw_flow:depends("sfe_flow", 0)
end

if luci.sys.call("cat /proc/cpuinfo | grep -q MT76") == 0 then
hw_flow = s:option(Flag, "hw_flow", translate("Hardware flow offloading"))
hw_flow.default = 0
hw_flow.description = translate("Requires hardware NAT support. Implemented at least for mt76xx")
hw_flow:depends("sw_flow", 1)
end

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/fast-classifier.ko") then
sfe_flow = s:option(Flag, "sfe_flow", translate("Shortcut-FE flow offloading"))
sfe_flow.default = 0
sfe_flow.description = translate("Shortcut-FE based offloading for routing/NAT")
sfe_flow:depends("sw_flow", 0)
end

sfe_bridge = s:option(Flag, "sfe_bridge", translate("Bridge Acceleration"))
sfe_bridge.default = 0
sfe_bridge.description = translate("Enable Bridge Acceleration (may be functional conflict with bridge-mode VPN server)")
sfe_bridge:depends("sfe_flow", 1)

if ipkg.installed("ip6tables") then
sfe_ipv6 = s:option(Flag, "sfe_ipv6", translate("IPv6 Acceleration"))
sfe_ipv6.default = 0
sfe_ipv6.description = translate("Enable IPv6 Acceleration")
sfe_ipv6:depends("sfe_flow", 1)
end

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/tcp_bbr.ko") then
bbr_cca = s:option(Flag, "bbr_cca", translate("BBR CCA"))
bbr_cca.default = 0
bbr_cca.rmempty = false
bbr_cca.description = translate("Using BBR CCA can improve TCP network performance effectively")
end 

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/xt_FULLCONENAT.ko") then
fullcone_nat = s:option(Flag, "fullcone_nat", translate("FullCone NAT"))
fullcone_nat.default = 0
fullcone_nat.rmempty = false
fullcone_nat.description = translate("Using FullCone NAT can improve gaming performance effectively")
end 

dns_acc = s:option(Flag, "dns_acc", translate("DNS Acceleration"))
dns_acc.default = 0
dns_acc.rmempty = false
dns_acc.description = translate("Using optimized DNS records for GoogleHosts (Don't use under Clash Fake-IP mode)")

dns_caching = s:option(Flag, "dns_caching", translate("DNS Caching"))
dns_caching.default = 0
dns_caching.rmempty = false
dns_caching.description = translate("Enable DNS Caching and anti ISP DNS pollution")

dns_caching_mode = s:option(ListValue, "dns_caching_mode", translate("Resolve Dns Mode"), translate("AdGuardHome login username/password: AdGuardHome/AdGuardHome"))
dns_caching_mode:value("1", translate("Using PDNSD to query and cache"))
if nixio.fs.access("/usr/bin/dnsforwarder") then
dns_caching_mode:value("2", translate("Using DNSForwarder to query and cache"))
end
if nixio.fs.access("/usr/bin/AdGuardHome") then
dns_caching_mode:value("3", translate("Using AdGuardHome to query and cache"))
end
dns_caching_mode.default = 1
dns_caching_mode:depends("dns_caching", 1)

dns_caching_v4_dns = s:option(Value, "dns_caching_v4_dns", translate("Upsteam IPv4 DNS Server"))
dns_caching_v4_dns.default = "114.114.114.114,114.114.115.115,223.5.5.5,223.6.6.6,180.76.76.76,119.29.29.29,119.28.28.28,1.2.4.8,210.2.4.8"
dns_caching_v4_dns.description = translate("Muitiple IPv4 DNS server can saperate with ','")
dns_caching_v4_dns:depends("dns_caching_mode", 1)
dns_caching_v4_dns:depends("dns_caching_mode", 2)

dns_caching_v6_dns = s:option(Value, "dns_caching_v6_dns", translate("Upsteam IPv6 DNS Server"))
dns_caching_v6_dns.default = "2001:4860:4860::8888,2001:4860:4860::8844,2001:2001::1111,2001:2001::1001,2400:da00::6666,240C::6666,240C::6644"
dns_caching_v6_dns.description = translate("Muitiple IPv6 DNS server can saperate with ','")
dns_caching_v6_dns:depends("dns_caching_mode", 2)

return m
