### 快速开始

1. 右上角Fork克隆本项目
2. 修改 `.github/workflows/build.yml`，在 `jobs.build.strategy` 修改 arch 和 sdk
  - 建议 arch 只保留需要的选项，加速编译
  - sdk 可根据需要填写，其中`SNAPSHOT`后缀的是apk安装包，`openwrt-22.03`的是ipk安装包（也可以根据自己的路由 OpenWRT 版本修改）
3. 到 actions 手动触发自动编译流程，注意需要填写 release，否则只编译不发布，参考下图：
 <img width="2727" height="866" alt="image" src="https://github.com/user-attachments/assets/24a55d1c-7937-4cef-87f8-cd8778b5f009" />


### 编译方法
```bash
#下载openwrt编译sdk到opt目录（不区分架构）
wget -qO /opt/sdk.tar.xz https://downloads.openwrt.org/releases/22.03.5/targets/rockchip/armv8/openwrt-sdk-22.03.5-rockchip-armv8_gcc-11.2.0_musl.Linux-x86_64.tar.xz
tar -xJf /opt/sdk.tar.xz -C /opt

cd /opt/openwrt-sdk*/package
#克隆luci-app-easytier到sdk的package目录里
git clone https://github.com/EasyTier/luci-app-easytier.git /opt/luci-app-easytier
cp -R /opt/luci-app-easytier/luci-app-easytier .

cd /opt/openwrt-sdk*
#升级脚本创建模板
./scripts/feeds update -a
make defconfig

#开始编译
make package/luci-app-easytier/compile V=s -j1

#编译完成后在/opt/openwrt-sdk*/bin/packages/aarch64_generic/base目录里
cd /opt/openwrt-sdk*/bin/packages/aarch64_generic/base
#移动到/opt目录里
mv *.ipk /opt/luci-app-easytier_all.ipk
```
