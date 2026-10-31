# 数独 · iOS 26 液态玻璃

一个从零手写的原生 iOS 数独游戏。**Objective-C + UIKit，零第三方依赖、零 Xcode 工程**——
16 个 `.m` + 15 个 `.h`，用 `clang + ld64.lld` 在命令行里直接编出可安装的 `.ipa`。

界面用 **iOS 26 的 Liquid Glass**（`UIGlassEffect` 真渲染），角色是同一套手绘风格的
熊猫 / 狐狸 / 老虎，通关有彩纸和星级动画，iPad 横屏自动变成「棋盘 + 右侧控制区」。

![图标](docs/Icon-1024.png)

## 液态玻璃是真的，不是画的

这是最容易搞错的一点，所以写在最前面：**液态玻璃是系统材质，只有用 iOS 26 SDK 编译的
app 才会被系统套上新设计**。用旧 SDK 编译，哪怕在代码里写满模糊和渐变，出来的也是旧外观。

判断依据是 Mach-O 里的 `LC_BUILD_VERSION`，本项目的正式构建必须是：

```
$ python3 scripts/macho_info.py Payload/Sudoku.app/Sudoku
platform : iOS
minos    : 15.0.0
sdk      : 26.5.0    <-- 必须是 26.x
```

- `sdk 26.5.0` → 系统按 iOS 26 渲染（玻璃导航栏、玻璃弹窗、玻璃按钮、滚动边缘效果）
- `minos 15.0.0` → 同一份包还能装在 iOS 15 及以上

| 位置 | 实现 |
| --- | --- |
| 棋盘底板 / 庆祝卡片 | `UIGlassEffect` + `UIVisualEffectView` |
| 6 个操作键、9 个数字键 | `+[UIButtonConfiguration glassButtonConfiguration]` |
| 放大镜 | 圆形 `UIGlassEffect`（`interactive`，跟手有反光）+ 矢量重绘格子 |
| 导航栏 / 弹窗 / 分段控件 | 系统组件，26 上自动是玻璃 |
| 背景 | 两团极淡的系统色光晕（alpha ≤ 0.13），给玻璃一点可折射的内容 |

`SDKMaterial` 是唯一碰这些 API 的地方。玻璃不可用时（旧 SDK 编译或系统低于 iOS 26）
自动退回系统语义色卡片，**不会用假模糊去冒充玻璃**。

## 角色与配图

三只动物对应三档难度，出现在首页难度行、历史记录、通关庆祝和空白状态里——**同一套画**，
所以不会显得东拼西凑：

| 角色 | 用在 |
| --- | --- |
| 熊猫（薄荷） | 简单 · 也是 app 图标 |
| 狐狸（杏色） | 中等 |
| 老虎（薰衣草） | 困难 |
| 睡着的熊猫（浅蓝） | 历史空白态 |

插画用同一段提示词生成，统一描边色与低饱和底色，再由 `scripts/make_mascots.py`
居中裁成圆形贴纸（4 倍超采样蒙版 + 调色板压缩，每张 10–16KB）。

**为什么没有引第三方 UI 库**：这台机器没有 Xcode，Swift 包（Lottie 之类）编不出静态库；
更重要的是，一个 app 里最容易产生「拼凑感」的做法就是混用几套第三方组件——圆角、动效
曲线、配色各说各话。这里的彩纸（`CAEmitterLayer`）、星级、涟漪都是几十行系统 API 写出来的，
风格只由 `SDKTheme` 一处定义。

## 通关动画

- 遮罩淡入 → 玻璃卡片弹簧入场（`usingSpringWithDamping:0.72`）→ 内容逐项浮起（每项错开 55ms）
- 角色轻轻呼吸（`CABasicAnimation` 循环），星星逐颗弹出来（弹过头一点再回弹）
- 彩纸从屏幕顶部撒下：6 种颜色、方块 + 圆片两种形状、带自旋与重力，撒 0.45 秒后停止发射，
  粒子落完自动移除图层
- 零失误零提示 = 3 星，失误 ≤2 且提示 ≤1 = 2 星，其余 1 星；刷新纪录时多一枚「本档新纪录」
- 棋盘同时从左上到右下逐格荡开涟漪（18ms ×（行+列）的差速）
- **Reduce Motion 打开时**：不放彩纸、不做弹簧，改成淡入淡出

## 历史与续玩

- 每局结束写入历史：难度、用时、失误、提示、完成度
- **没下完的局会连完整盘面一起存进历史**（最近 12 局），在历史里点一下就接着下——
  点按后这条记录会移回「继续对局」，不会重复出现
- 首页开新局时，旧局若已填过格子会自动存进历史，不再直接丢掉
- 统计里的「平均用时」只算完成的局，未完成的存档不会把它拉低

## iPad

- iPhone：单列，棋盘在上、控制条在下
- iPad 横屏（或够宽的 regular 宽度）：`rootStack` 转成水平，棋盘方形在左、控制区在右，
  6 个操作键变 3×2、9 个数字键变 3×3，控制列宽 368pt
- 支持全部四个方向 + 分屏 / 台前调度（已去掉 `UIRequiresFullScreen`）
- 布局随 `horizontalSizeClass` 与窗口比例自动切换，不需要重启

## 其余功能

- 三种难度（44 / 32 / 24 提示数），位掩码 + MRV 回溯生成，**每局校验唯一解**
- 放大镜：按住拖动，2.1× 玻璃圆内矢量重绘当前格子（不是截屏放大）
- 笔记、一键填满候选、自动清除关联笔记、撤销 / 重做（120 步）、提示
- 冲突标红、可选即时判错、失误计数、计时与暂停、切后台自动存档
- 统计：最佳 / 平均用时、完成率、最近七天柱状图（可左滑删除记录）
- 触感反馈、动态字体、VoiceOver 标签、浅色 / 深色自动

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
只想要旧外观也能编：`SDK=~/theos/sdks/iPhoneOS16.5.sdk bash scripts/build-ios.sh`
（玻璃相关代码会被裁掉，退回语义色卡片）。

资源脚本：`make_icon.py`（旧的纯网格图标）、`make_appicon.py`（角色图标）、
`make_mascots.py`（角色圆形贴纸）、`macho_info.py`（校验 SDK 版本）。

## 安装

ipa 未签名，任选一种自签安装：**TrollStore** / **ESign** / **Feather** / **Sideloadly**。

## 目录

```
Sudoku/
  main.m                    程序入口
  SDKAppDelegate.{h,m}      窗口 + 导航控制器
  SDKMaterial.{h,m}         液态玻璃入口（UIGlassEffect / 玻璃按钮），含旧系统回退
  SDKBackdropView.{h,m}     玻璃下方的淡色光晕
  SDKHomeViewController.*   首页（inset-grouped 列表，角色缩略图）
  SDKGameViewController.*   对局页（玻璃棋盘、键盘、计时、自适应布局）
  SDKCompletionOverlay.*    通关庆祝（玻璃卡、角色、星级、彩纸）
  SDKHistoryViewController.* 历史与统计（可续玩、柱状图）
  SDKSettingsViewController.* 设置
  SDKBoardView.*            9×9 绘制与触摸、落子涟漪
  SDKLoupeView.*            玻璃放大镜（矢量重绘）
  SDKBarChartView.*         最近七天柱状图
  SDKSudokuEngine.*         题目生成 / 求解器
  SDKGameState.*            一局状态、笔记、撤销栈、序列化
  SDKStore.*                NSUserDefaults 持久化（设置 / 存档 / 历史 / 统计）
  SDKTheme.*                语义色、字体、角色图、触感、格式化
Resources/                  Info.plist、图标与四张角色贴纸
scripts/                    构建、校验、图标与角色处理脚本
```

## 已知限制

- **没有在真机或模拟器上跑过**（本机是 Windows + WSL，没有 Xcode/模拟器）。正确性靠
  编译零警告、`LC_BUILD_VERSION` 校验（确认真的用上了 iOS 26 SDK），以及三轮针对布局、动画、持久化的代码审查。题目生成的唯一解由挖空时逐格 `SDKHasUniqueSolution` 保证。
- 玻璃观感依赖系统版本：iOS 26 上是真玻璃，iOS 15–25 上是语义色卡片。
- iPhone 仅竖屏；iPad 支持全部方向与分屏。
- 自带一条轻量「面包屑」诊断：万一异常退出，重新打开后「设置 → 关于」会多出
  「上次异常退出」，显示崩溃前停在哪个步骤（例如 `overlay.shown`），自签安装拿不到
  符号化 crash log 时这是最省事的替身。

## 许可

MIT，见 [LICENSE](LICENSE)。
