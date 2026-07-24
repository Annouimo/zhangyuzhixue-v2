# 章鱼智学静态官网

## 目录

- `index.html`：首页
- `software.html`：免费软件
- `courses.html`：系统课程总览
- `course-derivative.html`：导数系统课程
- `course-geometry.html`：解析几何系统课程
- `course-innovation.html`：创新题系统课程
- `team.html`：完整团队
- `about.html`：关于我们与联系方式
- `privacy.html`：隐私政策占位模板
- `terms.html`：用户协议占位模板
- `assets/css/site.css`：全站样式
- `assets/js/config.js`：下载链接、联系方式、备案信息等集中配置
- `assets/js/site.js`：导航、二维码弹窗、移动端菜单等交互

## 本地预览

直接双击 `index.html` 即可浏览。

也可以在网站目录运行：

```bash
python -m http.server 8080
```

然后访问 `http://localhost:8080/`。

## 上线前必须修改

1. 在 `assets/js/config.js` 替换 Android、iOS、Windows 下载链接。
2. 将 `assets/images/qr-wechat-placeholder.svg` 替换为正式微信二维码。
3. 将 `assets/images/logo-placeholder.svg` 替换为正式品牌图标。
4. 替换首页与软件页的软件截图占位区域。
5. 根据实际软件版本核对功能文案，删除尚未上线的功能。
6. 确认软件免费模式，避免使用不准确的长期承诺。
7. 核对全部团队成员姓名、职位、履历和公开授权。
8. 替换页脚运营主体、ICP备案和公安备案信息。
9. 使用正式的隐私政策与用户协议替换占位模板。
10. 核对课程试听、直播、回放和个性化服务的实际规则。

## 设计原则

- 简体中文静态网站
- 不设置表单、注册、登录、在线报名或支付
- 软件与课程同等重要
- 课程不公开价格，统一引导添加微信了解
- 电话保留，邮箱不展示
- 响应式适配电脑与手机
