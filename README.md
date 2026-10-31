# 数独 · iOS 26 液态玻璃

一个从零手写的原生 iOS 数独游戏。**Objective-C + UIKit，零第三方依赖、零 Xcode 工程**——
13 个 `.m` + 13 个 `.h`，用 `clang + ld64.lld` 在命令行里直接编出可安装的 `.ipa`。

界面用 **iOS 26 的 Liquid Glass**：玻璃面板、玻璃按钮、玻璃放大镜都是系统用
`UIGlassEffect` / `UIButtonConfiguration.glassButtonConfiguration` 真渲染出来的，
不是自己画的渐变和假模糊。

![图标](docs/Icon-1024.png)

## 液态玻璃是真的，不是画的

这是最容易搞错的一点，所以写在最前面：**液态玻璃是系统材质，只有用 iOS 26 SDK 编译的
app 才会被系统套上新设计**。用旧 SDK 编译，哪怕你在代码里写满模糊和渐变，出来的也是旧外观。

判断依据是 Mach-O 里的 `LC_BUILD_VERSION`，本项目的正式构建必须是：

```
$ python3 scripts/macho_info.py Payload/Sudoku.app/Sudoku
platform : iOS
minos    : 15.0.0
sdk      : 26.5.0    <-- 必须是 26.x
```

- `sdk 26.5.0` → 系统按 iOS 26 渲染（玻璃导航栏、玻璃弹窗、玻璃按钮、滚动边缘效果）
- `minos 15.0.0` → 同一份包还能装在 iOS 15 及以上

具体用到的系统 API：

| 位置 | 实现 |
| --- | --- |
| 棋盘底板 | `UIGlassEffect` + `UIVisualEffectView`，圆角 26 |
| 6 个操作键（撤销/重做…） | `+[UIButtonConfiguration glassButtonConfiguration]` |
| 9 个数字键 | 同上，选中笔记时用 `prominentGlassButtonConfiguration` |
| 放大镜 | 圆形 `UIGlassEffect`（`interactive = YES`，跟手有反光）+ 矢量重绘格子 |
| 导航栏 / 弹窗 / 分段控件 | 系统组件，26 上自动是玻璃 |
| 背景 | 两团极淡的系统色光晕（alpha ≤ 0.13），给玻璃一点可折射的内容 |

`SDKMaterial` 是唯一碰这些 API 的地方。玻璃不可用时（旧 SDK 编译，或系统低于 iOS 26）
自动退回系统语义色卡片，**不会用假的模糊去冒充玻璃**。

## 功能

- **三种难度**：简单 44 / 中等 32 / 困难 24 提示数；位掩码 + MRV 回溯生成，**每局校验唯一解**
- **放大镜**：按住棋盘拖动，浮起 2.1× 玻璃放大镜，按矢量重绘当前格子（不是截屏放大）
- **笔记**：笔记模式、一键填满候选、自动清除关联笔记
- **撤销 / 重做**（120 步）、**提示**（自动挑最该填的格子）
- **冲突提示**：同行列宫重复标红、可选即时判错、失误计数
- **计时与暂停**：切后台自动暂停并自动存档，回前台询问是否继续
- **历史与统计**：每局记录（左滑删除）、最佳 / 平均用时、完成率、最近七天柱状图
- **断点续玩**、触感反馈、动态字体、VoiceOver 标签、浅色 / 深色自动

## 编译（不需要 Mac、不需要 Apple 账号）

需要 `clang`、`ld64.lld` 和一份 iOS SDK。

```bash
# 1) 拿一份带 iOS 26 的 SDK（只取头文件和 stub，约 310MB）
git clone --filter=blob:none --sparse --depth 1 https://github.com/xybp888/iOS-SDKs.git ~/sdk26
cd ~/sdk26 && git sparse-checkout set --no-cone \
    "/iPhoneOS26.5.sdk/usr/include/**" "/iPhoneOS26.5.sdk/usr/lib/**" \
    "/iPhoneOS26.5.sdk/System/Library/Frameworks/**" \
    "/iPhoneOS26.5.sdk/System/Library/PrivateFrameworks/**/*.tbd" \
    "/iPhoneOS26.5.sdk/System/Library/SubFrameworks/**" \
    "/iPhoneOS26.5.sdk/SDKSettings.plist"

# 2) 编
bash scripts/check.sh        # 逐文件语法/类型检查
bash scripts/build-ios.sh    # 产出仓库根目录的 Sudoku-unsigned.ipa

# 3) 确认打进去的是新设计
python3 scripts/macho_info.py out/Sudoku.app/Sudoku    # sdk 应为 26.x
```

指定 SDK：`SDK=/path/to/iPhoneOS26.5.sdk bash scripts/build-ios.sh`。
只想要旧外观（例如用 theos 的公开 SDK）也能编：
`SDK=~/theos/sdks/iPhoneOS16.5.sdk bash scripts/build-ios.sh` —— 玻璃相关代码会被裁掉。

图标由 `scripts/make_icon.py` 用 Pillow 按精确几何绘制并导出全部尺寸（扁平、无圆角、无透明）。

## 安装

ipa 未签名，任选一种自签安装：**TrollStore** / **ESign** / **Feather** / **Sideloadly**。

## 目录

```
Sudoku/
  main.m                    程序入口
  SDKAppDelegate.{h,m}      窗口 + 导航控制器
  SDKMaterial.{h,m}         液态玻璃入口（UIGlassEffect / 玻璃按钮），含旧系统回退
  SDKBackdropView.{h,m}     玻璃下方的淡色光晕
  SDKHomeViewController.*   首页（inset-grouped 列表）
  SDKGameViewController.*   对局页（玻璃棋盘、键盘、计时、暂停/通关）
  SDKHistoryViewController.* 历史与统计
  SDKSettingsViewController.* 设置
  SDKBoardView.*            9×9 绘制与触摸（放大镜复用同一套绘制）
  SDKLoupeView.*            玻璃放大镜（矢量重绘）
  SDKBarChartView.*         最近七天柱状图
  SDKSudokuEngine.*         题目生成 / 求解器
  SDKGameState.*            一局状态、笔记、撤销栈
  SDKStore.*                NSUserDefaults 持久化
  SDKTheme.*                语义色、字体、触感、格式化
Resources/                  Info.plist 与图标
scripts/                    check.sh、build-ios.sh、make_icon.py、macho_info.py
```

## 已知限制

- **没有在真机或模拟器上跑过**（本机是 Windows + WSL，没有 Xcode/模拟器）。正确性靠
  编译零警告、`LC_BUILD_VERSION` 校验、以及题目生成器的 600 局对拍（数组一致、唯一解、
  解可还原）。
- 玻璃的实际观感依赖系统版本：iOS 26 上是真玻璃，iOS 15–25 上是语义色卡片。
- 仅竖屏；iPad 上内容宽度限制 520pt。

## 许可

MIT，见 [LICENSE](LICENSE)。
