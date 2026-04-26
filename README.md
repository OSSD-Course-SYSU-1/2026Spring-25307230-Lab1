# 视频字幕播放器

## 项目简介

本示例实现了功能丰富的视频字幕播放器，支持视频选择、语音识别生成字幕、倍速播放等功能。分别使用AVPlayer实例和Video组件两种方式实现视频播放，支持外挂字幕和字幕样式设置。

## 主要功能

- ✅ **视频选择**：从相册中选择视频文件进行播放
- ✅ **语音识别生成字幕**：实时识别视频中的语音，自动生成字幕文件
- ✅ **倍速播放**：支持 0.5x、0.75x、1.0x、1.25x、1.5x、2.0x 多档倍速播放
- ✅ **字幕样式设置**：支持设置字幕字体格式、大小、颜色
- ✅ **双播放器支持**：AVPlayer 和 Video 组件两种播放方式

## 效果预览

| 应用首页   | <img src="./screenshots/devices/home.jpg" height="320">         |
|:-------|-----------------------------------------------------------------|
| 应用效果展示 | <img src="./screenshots/devices/captionVideo.gif" height="320"> |

## 使用说明

### 基本使用
1. 打开应用，点击"选择视频"按钮，从相册中选择视频文件
2. 点击"AVPlayer外挂字幕"或"Video组件外挂字幕"按钮进入播放页面
3. 点击下方字幕设置按钮，可以设置字幕格式、大小、颜色

### 语音识别生成字幕
1. 选择视频后，点击"生成字幕（语音识别）"按钮
2. 系统会初始化语音识别引擎，请等待提示"请开始说话..."
3. 对着麦克风说话，系统会实时识别语音内容并显示进度
4. 识别完成后，系统会自动生成字幕文件
5. 生成的字幕会自动应用到视频播放中

### 倍速播放
1. 在视频播放页面，点击倍速按钮（显示当前倍速，如 `1.0x`）
2. 在弹出的倍速选择面板中选择所需倍速
3. 视频将按照选择的倍速播放

## 工程目录

```
├──entry/src/main/ets/                              
│  ├──constants
│  │  └──Constants.ets                              // 常量文件
│  ├──entryability
│  │  └──EntryAbility.ets                           // 程序入口类
│  ├──entrybackupability
│  │  └──EntryBackupAbility.ets                     // 备份入口类
│  ├──model  
│  │  └──ViewModel.ets                              // 视频播放参数类     
│  ├──pages  
│  │  ├──Index.ets                                  // 首页入口页面           
│  │  └──VideoPage.ets                              // 视频播放页
│  ├──utils                                         
│  │  ├──CommonUtil.ets                             // 公共工具类
│  │  ├──Logger.ets                                 // 日志类
│  │  ├──VideoPickerUtil.ets                        // 视频选择工具类
│  │  ├──SpeechRecognizerUtil.ets                   // 语音识别工具类
│  │  └──SubtitleGeneratorUtil.ets                  // 字幕生成工具类
│  └──view             
│     ├──AvPlayerComponent.ets                      // AVPlayer视频播放组件
│     ├──CaptionFontComponent.ets                   // 字幕字体设置组件
│     └──VideoPlayerComponent.ets                   // Video视频播放组件
└──entry/src/main/resources                         // 应用静态资源目录
```

## 具体实现

### 视频播放与字幕显示
1. **AVPlayer实例**：注册 `on('subtitleUpdate')` 方法监听字幕信息，使用状态变量刷新Text组件内容，并通过改变Text属性修改字幕格式。
2. **Video组件**：Update监听视频进度，更新字幕信息，使用状态变量刷新Text组件内容，并通过改变Text属性修改字幕格式。

### 视频选择功能
- 使用 HarmonyOS `photoAccessHelper.PhotoViewPicker` 实现视频选择
- 支持从相册中选择单个视频文件
- 通过 `@Provide/@Consume` 装饰器实现跨组件数据共享

### 语音识别功能
- 使用 HarmonyOS 原生 `speechRecognizer` API
- 支持中文语音识别（zh-CN）
- 采用离线识别模式，保护用户隐私
- 实时回调识别结果，自动生成字幕

### 字幕生成功能
- 根据语音识别结果自动生成字幕
- 每段语音默认3秒时长
- 支持 SRT 格式输出
- 自动合并重叠字幕

### 倍速播放功能
- **AVPlayer**：使用 `avPlayer.setSpeed()` 方法，支持 `media.PlaybackSpeed` 枚举
- **Video组件**：使用 `currentProgressRate` 属性设置播放速度
- 支持 0.5x、0.75x、1.0x、1.25x、1.5x、2.0x 多档倍速

## 相关权限

本应用需要以下权限：

1. **ohos.permission.READ_MEDIA** - 读取媒体文件权限（用于从相册选择视频）
2. **ohos.permission.MICROPHONE** - 麦克风权限（用于语音识别）
3. **ohos.permission.INTERNET** - 网络权限（用于网络视频播放）

权限已在 `module.json5` 中配置，应用会自动申请所需权限。

## 约束与限制

1. 本示例仅支持标准系统上运行，支持设备：华为手机、平板。

2. HarmonyOS系统：HarmonyOS 5.1.1 Release及以上。

3. DevEco Studio版本：DevEco Studio 5.1.1 Release及以上。

4. HarmonyOS SDK版本：HarmonyOS 5.1.1 Release SDK及以上。

5. 语音识别功能：
   - 短语音模式支持最长60秒
   - 需要设备支持语音识别能力
   - 建议在安静环境下使用以获得最佳识别效果

6. 倍速播放：
   - Video组件仅支持特定倍速值（0.75、1.0、1.25、1.75、2.0）
   - AVPlayer支持更灵活的倍速设置

## 技术要点

### 状态管理
- 使用 `@State` 管理组件内部状态
- 使用 `@Prop` 接收父组件传递的属性
- 使用 `@Link` 实现双向数据绑定
- 使用 `@Provide/@Consume` 实现跨组件数据共享

### 视频播放
- AVPlayer：功能强大，支持更多控制选项
- Video组件：声明式语法，使用简单

### 语音识别流程
1. 初始化语音识别引擎
2. 设置识别回调监听
3. 开始监听音频输入
4. 实时接收识别结果
5. 生成字幕文件
6. 释放引擎资源

### 字幕格式
- 支持 SRT 标准格式
- 包含时间轴和文本内容
- 自动同步视频播放进度

## 更新日志

### v2.0.0 (2025-04-21)
- ✨ 新增视频选择功能
- ✨ 新增语音识别生成字幕功能
- ✨ 新增倍速播放功能
- 🎨 优化用户界面和交互体验
- 📝 更新项目文档

### v1.0.0
- 🎉 初始版本
- ✅ 支持视频外挂字幕
- ✅ 支持字幕样式设置
