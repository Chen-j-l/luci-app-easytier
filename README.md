### 说明
此版本是根据官方版本自定义而来，删除上传bin文件，删除web控制台，修改参数配置方法，修改显示参数方式，删除网络及防火墙自动配置功能，改动布局。

### 快速开始

1. 右上角Fork克隆本项目
2. 修改 `.github/workflows/build.yml`，在 `jobs.build.strategy` 修改 arch 和 sdk
  - 建议 arch 只保留需要的选项，加速编译
  - sdk 可根据需要填写，其中`SNAPSHOT`后缀的是apk安装包，`openwrt-22.03`的是ipk安装包（也可以根据自己的路由 OpenWRT 版本修改）
3. 到 actions 手动触发自动编译流程，注意需要填写 release，否则只编译不发布，参考下图：
 <img width="2727" height="866" alt="image" src="https://github.com/user-attachments/assets/24a55d1c-7937-4cef-87f8-cd8778b5f009" />
