# 数独 · Liquid Glass

<img src="docs/Icon-1024.png" width="120" align="right" />

一个从零手写的原生 iOS 数独游戏。**Objective-C + UIKit，零第三方依赖，零配置工程**——
没有 Xcode 工程、没有 CocoaPods、没有 Swift Package，只有 20 个 `.m/.h` 文件，
用 `clang + ld64.lld` 就能直接编译出可安装的 `.ipa`。

界面按 **iOS 26 的 Liquid Glass 语言**设计：磨砂玻璃面板、高光描边、随背景流动的极光渐变、
可形变的选中光环。因为全部是自绘的 CALayer 合成，所以在任何 iOS 版本的设备上观感一致。

> 已适配 iOS 26 的视觉与交互习惯；最低支持 iOS 15，iPad 与 iPhone 通用（仅竖屏）。

---

## ✨ 功能

| 分类 | 能力 |
| --- | --- |
| 对局 | 三种难度（简单 44 / 中等 32 / 困难 24 个提示数），**每局都保证唯一解** |
| 输入 | 数字键盘（带剩余可用数量角标）、点按棋盘点选、**按住拖动连续选格** |
| 笔记 | 铅笔笔记模式、一键填充全部候选笔记、自动清理关联笔记 |
| 辅助 | 撤销 / 重做（可回溯 100+ 步）、擦除、提示（自动选择最优待填格） |
| 判错 | 高亮同行/同列/同宫、点亮相同数字、标记重复、可选的「即时判错」 |
| 放大镜 | **按住任意格子，手指上方浮起真实放大镜**，以 2.15× 重绘该格及周边，看清数字与笔记；也可用右上角按钮固定显示当前格 |
| 计分 | 计时、暂停（离开前台自动暂停）、失误次数、提示次数 |
| 历史 | 每局自动存档，中断后回到首页可「继续对局」；完整对局记录（完成/未完成、用时、失误） |
| 统计 | 总对局、完成率、最佳用时、分难度统计、最近 7 天完成数柱状图 |
| 体验 | 触感反馈、Spring 动画、通关礼花、深色主题、进度自动保存 |

---

## 🧊 液态玻璃是怎么画的

`SDKGlassView` 是一个 30 行的合成配方，所有面板、按钮、卡片都复用它：

1. `UIVisualEffectView`（`systemUltraThinMaterialDark`）做真实磨砂；
2. 一层斜向白色渐变（0.055 → 0.017）给玻璃质感；
3. 顶部 sheen 渐变模拟折射高光；
4. **渐变描边**：`CAGradientLayer` 被一条 `CAShapeLayer` 的描边遮罩挖空，
   得到「左上亮、中间暗、右下微亮」的液态玻璃轮廓光；
5. 大面积卡片额外挂一条缓慢扫过的斜向光带（`ambientSheen`）；
6. 圆角使用 `kCACornerCurveContinuous`，与 iOS 的连续曲率一致。

背景 `SDKAuroraView` 是 4 团 `kCAGradientLayerRadial` 光斑，以 26~34 秒的周期相互漂移，
外加一层径向暗角——玻璃面板折射的就是它。

---

## 🔍 放大镜为什么"真"放大

`SDKLoupeView` 不是把截图放大，而是拿到棋盘的坐标系与格子边长，
按 `magnification` 重新绘制手指附近的格子、网格线、数字与笔记，
裁剪进圆形玻璃并画上高光环。所以放大后依然**清晰不模糊**，也能看到铅笔笔记。

---

## 🧮 生成器

`SDKSudokuEngine` 用位掩码 + MRV（最少候选优先）回溯法：

- 随机填满终盘 → 180° 对称挖空（简单/中等），每一步都用「数解数 ≤ 1」校验唯一性；
- 困难难度做**最小化挖空**（多轮随机移除直到每一格都不可再删），得到 23~26 提示数的极限局面；
- 单局生成耗时：简单/中等 < 1ms，困难约 3~8ms（A 系列芯片更快）。

---

## 🚀 自己编译（Windows / Linux，无需 Mac）

需要 `clang`、`ld64.lld`、一份 iPhoneOS SDK（[theos/sdks](https://github.com/theos/sdks)）、`zip`。

```bash
# 只做类型检查
./scripts/check.sh

# 产出未签名 ipa
SDKROOT=~/theos/sdks MINIOS=15.0 ./scripts/build-ios.sh
# -> ~/ios-ipa-kit/out/Sudoku-unsigned.ipa
```

核心就是这几步（`scripts/build-ios.sh` 里可读全文）：

```bash
clang -target arm64-apple-ios15.0 -isysroot "$SDK" -fobjc-arc -O2 -c Sudoku/*.m
ld64.lld-18 -arch arm64 -platform_version ios 15.0 16.5 -syslibroot "$SDK" \
    -L"$SDK/usr/lib" -lSystem -framework UIKit -framework Foundation \
    -framework CoreGraphics -framework CoreFoundation -framework QuartzCore -o Sudoku *.o
mkdir -p Payload/Sudoku.app && cp Sudoku Info.plist PkgInfo Payload/Sudoku.app/
zip -qry Sudoku-unsigned.ipa Payload
```

---

## 📲 安装未签名 ipa

本仓库产物**不包含任何签名**，请用下列任一方式自签安装：

- **TrollStore**（iOS 14~17 部分版本）：直接打开 ipa 即可安装；
- **ESign / Feather / Sideloadly**：准备自己的 `.p12` + `.mobileprovision` 后签名安装；
- 越狱设备：`ldid -S` 后 `dpkg`/`appinst` 安装。

> ipa 见 [Releases](../../releases)。未签名 ipa 在普通未越狱设备上需要自签，这是 iOS 的限制。

---

## 📁 目录结构

```
Sudoku/
├── main.m                     入口
├── SDKAppDelegate.{h,m}       应用生命周期
├── SDKNavigationController    无导航条导航
├── SDKTheme.{h,m}             设计系统：配色 / 字体 / 触感
├── SDKGlass.{h,m}             液态玻璃组件（面板 / 按钮 / 胶囊 / 开关）
├── SDKAuroraView.{h,m}        极光背景
├── SDKBoardView.{h,m}         9×9 棋盘（Core Graphics 自绘）
├── SDKLoupeView.{h,m}         放大镜
├── SDKBarChartView.{h,m}      统计柱状图
├── SDKSudokuEngine.{h,m}      出题 / 求解 / 唯一解校验
├── SDKGameState.{h,m}         棋局状态、笔记、撤销栈
├── SDKStore.{h,m}             设置、进度、历史、统计持久化
├── SDKHomeViewController      首页
├── SDKGameViewController     对局页
├── SDKHistoryViewController  历史 / 统计
├── SDKSettingsViewController 设置
└── Resources/                 Info.plist 与图标
```

---

## ⚠️ 已知限制

- 只出未签名 ipa，签名与安装由你自己完成；
- 仅竖屏、仅深色（液态玻璃在深色背景上效果最好，也避免了两套配色带来的视觉不一致）；
- 没有联网、没有账号、没有广告、不收集任何数据。

---

## 📄 License

[MIT](LICENSE) © 2026 shimiei
