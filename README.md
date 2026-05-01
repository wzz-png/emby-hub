# Emby Hub

一款跨平台的 Emby 媒体播放器客户端，采用 iOS 风格毛玻璃 (Glassmorphism) 设计语言，基于 Flutter 构建。

## 功能特性

- **多平台支持** - Windows / macOS / Linux / Android / iOS / Web
- **多播放引擎** - MPV (media_kit) / MDK (fvp) / VLC 三引擎可切换
- **毛玻璃 UI** - 全局 iOS 风格 Glassmorphism 设计体系
- **媒体浏览** - 首页推荐、媒体库网格浏览、排序筛选、无限滚动
- **影片详情** - 海报视差、剧情简介、季集选择、相似推荐
- **演员系统** - 演员详情页（头像 / 简介 / 参演作品网格）、演员收藏
- **收藏管理** - 独立收藏 Tab，收藏影片 / 收藏演员双 Tab 切换
- **全局搜索** - 实时搜索，支持电影、剧集、演员等多类型
- **播放控制** - 进度记忆、播放上报、硬件加速、字幕 / 音轨切换
- **登录持久化** - 安全存储认证信息，应用重启自动恢复会话
- **响应式布局** - 手机底部导航 / 平板折叠侧栏 / 桌面完整侧栏自适应

## 截图

> 连接 Emby 服务器后即可体验完整功能。

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.41+ / Dart 3.11+ |
| 状态管理 | Riverpod (StateNotifierProvider) |
| 路由 | GoRouter (StatefulShellRoute) |
| 网络 | Dio + 拦截器链 (认证/日志/错误) |
| 播放器 | media_kit (MPV) / fvp (MDK) / flutter_vlc_player |
| 存储 | FlutterSecureStorage |
| 图片 | CachedNetworkImage |
| 桌面 | window_manager |

## 项目结构

```
lib/
├── app/                          # 应用入口、路由、Shell 导航
│   ├── app.dart                  # 根 Widget (会话恢复)
│   ├── router.dart               # GoRouter 路由配置
│   ├── shell_scaffold.dart       # 底栏/侧栏导航壳
│   └── bootstrap.dart            # 平台初始化
│
├── core/
│   ├── api/                      # Emby API 层
│   │   ├── emby_client.dart      # Dio HTTP 客户端
│   │   ├── emby_repository.dart  # API 方法封装
│   │   ├── endpoints.dart        # 端点常量
│   │   ├── models/               # 数据模型 (MediaItem, PersonInfo 等)
│   │   └── interceptors/         # 认证/日志/错误拦截器
│   ├── player/                   # 多引擎播放器
│   │   ├── player_backend.dart   # 抽象接口 + PlayerEngine 枚举
│   │   ├── mpv_backend.dart      # MPV (media_kit)
│   │   ├── mdk_backend.dart      # MDK (fvp + video_player)
│   │   ├── vlc_backend.dart      # VLC (flutter_vlc_player)
│   │   └── player_manager.dart   # 引擎工厂
│   ├── theme/                    # 主题 / 颜色 / 毛玻璃效果
│   └── providers.dart            # 核心 Provider 注册
│
├── features/
│   ├── auth/                     # 登录认证 (持久化)
│   ├── home/                     # 首页 (推荐/继续观看/最新)
│   ├── library/                  # 媒体库 (网格/排序/筛选/分页)
│   ├── search/                   # 搜索 (防抖/历史)
│   ├── favorites/                # 收藏 (影片/演员双 Tab)
│   ├── detail/                   # 影片详情 (视差/季集/演员/推荐)
│   ├── person/                   # 演员详情 (头像/简介/作品网格)
│   ├── video_player/             # 视频播放器
│   ├── profile/                  # 个人资料
│   └── settings/                 # 设置 (播放引擎切换等)
│
└── shared/
    ├── widgets/                  # 毛玻璃组件库 (GlassButton/Card/Chip 等)
    ├── animations/               # 动画 (交错入场/视差/弹性曲线)
    └── layouts/                  # 响应式布局 (断点自适应)
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- 一个可访问的 Emby Server

### 安装与运行

```bash
# 克隆项目
git clone https://github.com/wzz-png/emby-hub.git
cd emby-hub

# 安装依赖
flutter pub get

# 运行 (选择目标平台)
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos           # macOS
flutter run                    # 已连接的移动设备
```

### 构建发布版

```bash
flutter build apk --release        # Android APK
flutter build appbundle --release   # Android AAB
flutter build windows --release     # Windows
flutter build ios --release         # iOS
flutter build web --release         # Web
```

### Docker 部署

```bash
# 从 GHCR 拉取镜像
docker pull ghcr.io/wzz-png/emby-hub:latest

# 运行容器
docker run -d -p 8080:80 --name emby-hub ghcr.io/wzz-png/emby-hub:latest

# 访问 http://localhost:8080
```

也可以本地构建镜像：

```bash
docker build -t emby-hub .
docker run -d -p 8080:80 emby-hub
```

## CI/CD

项目配置了 GitHub Actions 自动构建流水线 (`.github/workflows/build.yml`)：

- **触发条件**: 推送 `v*` 标签 或 手动触发
- **构建矩阵**: Android (APK/AAB) / Windows (ZIP) / iOS (IPA) / Web / Docker
- **自动发布**: Tag 触发时自动创建 GitHub Release 并上传安装包
- **Docker 镜像**: 自动构建并推送到 GitHub Container Registry (ghcr.io)

```bash
# 触发自动打包
git tag v1.0.0
git push origin v1.0.0
```

## Emby API 对接

已实现的 API 功能：

| 功能 | 端点 |
|------|------|
| 服务器连接 | `GET /System/Info/Public` |
| 用户认证 | `POST /Users/AuthenticateByName` |
| 媒体浏览 | `GET /Users/{id}/Items` (排序/筛选/分页) |
| 影片详情 | `GET /Users/{id}/Items/{itemId}` |
| 相似推荐 | `GET /Items/{id}/Similar` |
| 季集数据 | `GET /Shows/{id}/Seasons`, `/Episodes` |
| 演员作品 | `GET /Users/{id}/Items?PersonIds=` |
| 收藏管理 | `POST/DELETE /Users/{id}/FavoriteItems/{itemId}` |
| 播放控制 | `POST /Sessions/Playing`, `/Progress`, `/Stopped` |
| 搜索 | `GET /Users/{id}/Items?SearchTerm=` |

## 许可证

MIT License
