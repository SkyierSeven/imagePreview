# imagePreview

面向 macOS 的轻量看图 / 看漫画工具。打开一张图后，可在同目录内连续翻页，支持触控板手势、沉浸全屏和日漫阅读方向。

用 SwiftUI + AppKit 写成，刻意不做裁剪、标注、删除等重功能。

## 功能

- **目录关联翻页**：打开单张图后自动关联同目录图片；← → / 侧边按钮 / 触控板滑动切页（到头停止）
- **单窗口**：再次打开图片会替换当前内容，不堆窗口
- **沉浸阅读**：`F` 或双击进入全屏黑底；`Esc` 退出
- **日漫方向**：更多 →「从右到左」后，左侧 / ← 为下一页
- **显示模式**：适应窗口 / 填满 / 实际大小 / 拉伸
- **旋转**：仅影响显示，切页后保留
- **自定义快捷键**：更多 → 自定义切图快捷键（方向键始终保留）
- **跟随系统语言**：菜单中英随系统切换

## 系统要求

- macOS 14.0+
- Apple Silicon / Intel 均可（Universal 需本地自行配置；CI 默认打当前 runner 架构）

## 安装

### 方式一：从 GitHub Releases 下载（推荐）

1. 打开 [Releases](https://github.com/SkyierSeven/imagePreview/releases)
2. 下载 `imagePreview-macos.zip`，解压得到 `imagePreview.app`
3. 首次打开若被 Gatekeeper 拦截：右键 App → 打开 → 仍要打开  
   （CI 产物为 ad-hoc 签名，未做 Apple 公证）

### 方式二：本地编译

依赖：[XcodeGen](https://github.com/yonaskolb/XcodeGen)（可选；仓库已含 `.xcodeproj`）

```bash
# 若改过 project.yml，先重新生成工程
brew install xcodegen   # 如需要
xcodegen generate

# Xcode 打开
open imagePreview.xcodeproj

# 或命令行 Release 构建
xcodebuild -scheme imagePreview -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=NO
open build/Build/Products/Release/imagePreview.app
```

## 使用说明

1. 拖入图片，或 `⌘O` 打开，或在 Finder 中用本 App 打开图片  
2. 用键盘、侧边按钮或触控板左右滑翻页  
3. 右上角「更多」可切换沉浸、日漫方向、显示模式、旋转与自定义快捷键  
4. 看漫画时可开「沉浸阅读」+「从右到左」

## 快捷键

| 按键 | 作用 |
|------|------|
| ← → | 空间上一张 / 下一张（开启日漫后左右含义对调） |
| ↑ ↓ | 按文件顺序上一张 / 下一张 |
| 触控板左右滑 | 左滑下一张，右滑上一张（一次滑动只切一张） |
| 侧边按钮 | 鼠标移动时显示，静止约 2 秒隐藏 |
| `F` / 双击画面 | 进入或退出沉浸 |
| `Esc` | 退出沉浸 |
| `0` | 适应窗口 |
| `1` | 实际大小 |
| `S` | 拉伸填满 |
| `R` / `Shift+R` | 顺时针 / 逆时针旋转 |
| `⌘O` | 打开… |
| `⌘Q` | 退出 |

自定义切图键：更多 →「自定义切图快捷键…」（不能覆盖方向键）。

## 支持格式

`jpg` `jpeg` `png` `heic` `heif` `webp` `gif` `tif` `tiff` `bmp`

GIF 当前按静帧显示。

## 持续集成 / 打包

仓库使用 GitHub Actions（`.github/workflows/build-release.yml`）：

| 触发 | 行为 |
|------|------|
| `push` / `pull_request`（`main`） | Release 编译并上传 `imagePreview-macos.zip` Artifact |
| `workflow_dispatch` | 手动跑打包 |
| 推送 tag `v*`（如 `v1.1.0`） | 编译并创建 GitHub Release，附带 zip |

本地等价命令见上方「本地编译」。

## 项目结构

```
Sources/           # Swift 源码
Resources/         # Info.plist、图标、Localizable.xcstrings
project.yml        # XcodeGen 工程描述
imagePreview.xcodeproj/
.github/workflows/ # CI
```

## 已知限制

- 未做 Developer ID 签名与公证，分发安装需用户手动允许  
- 不做编辑、裁剪、删除、多窗口、条漫连续竖滑（竖长 Webtoon）  
- 预读相邻页、设为系统默认看图器等可后续增强  

## License

MIT — 见 [LICENSE](LICENSE)
