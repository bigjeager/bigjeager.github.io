---
title: "🎵 SingTheWord:一个 vibe coding 出来的「听歌背单词」应用"
description: "把单词书里的例句换成真实歌词,把机翻朗读换成歌曲原声——用 AI 结对 vibe 出来的雅思单词 Web 应用,Demo 与实现思路"
date: 2026-09-25T02:30:00+08:00
draft: false
tags: ["Vibe Coding", "AI", "英语学习", "Web", "项目"]
categories: ["项目"]
author: "BigJeager"
showToc: true
---

## 🤔 起因

背雅思单词这件事,最大的问题不是"记不住",而是**无聊**——单词书里那句 "He achieved his goal through hard work" 式的例句,读 third 遍的时候灵魂就已经出窍了。

但歌词不一样。一句你单曲循环过一百遍的歌词,里面出现过的单词想忘都忘不掉。于是我做了这个实验性的小项目:**SingTheWord**,让每个雅思单词都"住在"一首真实的歌里。

## 🎧 它长什么样

<p align="center">
  <img src="/images/singtheword/preview-desktop.png" alt="桌面版:播放中的卡片展开卡拉OK双语歌词" style="max-width:100%;" />
</p>
<p align="center">
  <img src="/images/singtheword/preview-mobile.png" alt="手机版:整卡歌词与迷你播放器" width="300" />
</p>

**在线体验(demo):** [https://bigjeager.github.io/singtheword/](https://bigjeager.github.io/singtheword/)
**源码:** [github.com/bigjeager/singtheword](https://github.com/bigjeager/singtheword)

## 🎤 它能干什么

- **100 个雅思核心词**,每个词配一句**包含它的真实歌词**,并直接播放那首歌的 **30 秒官方原声试听**(Apple Music / iTunes 版权音频,不是 TTS 朗读);
- **卡拉OK式双语歌词**:播放时逐句歌词(英文 + 中文对照)随歌声自动滚动、当前句高亮,点任意句子可以跳转到那句——像 KTV 一样;
- **「本片段包含」**:每张卡片列出这 30 秒里出现的其他主列表单词,点一下就能切换,一首歌多学几个词;
- **像刷歌单一样背单词**:桌面端滚动页面、手机端左右滑动卡片,滑到哪张播哪张,片段播完自动连播下一个;
- **学习管理**:星标"已学会"、进度条、筛选、搜索、随机一词,本地保存;
- **纯静态、零后端**:整个应用就是几个 HTML/JS 文件,托管在 GitHub Pages 上。

## ⚙️ 三个有意思的技术点

整个项目是 vibe coding 的产物——我和 AI 结对,从想法到上线。但拆开看,有三个问题值得一记:

### 1. 原声片段从哪来

不自己存音频,而是调用 **iTunes Search API**,拿每首歌官方的 30 秒试听(`previewUrl`)和专辑封面。音频永远从 Apple 的 CDN 热链,仓库里一个字节的音乐都没有,版权上干净很多。

### 2. 卡拉OK是怎么对齐的(最难的一步)

iTunes 的试听是**原曲中间随便截的 30 秒**,Apple 不会告诉你起点在第几秒。解法是个土办法但意外地好用:

1. 从 **LRCLIB** 拿整首歌逐行带时间轴的 LRC 歌词;
2. 把 30 秒试听下载下来,用 **faster-whisper**(本地语音识别)转写;
3. 把转写结果和 LRC 歌词逐行做模糊匹配,**中位数偏移**即试听片段在全曲中的真实起点。

绝大多数歌曲匹配置信度能到 0.9–1.0,卡拉OK字幕就这么同步起来了。

### 3. "以片段为中心"选词

最初的想法是先选 100 个词、再给每个词找歌,但很快发现:目标词经常根本不落在试听的 30 秒窗口里。于是把数据流反了过来——**以片段为中心**:只保留(或替换成)歌词窗口里**真实出现**的单词,词不在窗口里的歌一律换歌换词。最终 100 个词落在 67 首歌上,每个词都保证"边听边见"。

## 💭 一点 vibe coding 感受

这个项目让我对 vibe coding 的体感是:**AI 负责手速,人负责品味和决策**。

数据管线里的坑——iTunes 接口限流、歌词库没有同步歌词、whisper 对不上电子乐、宽松词形匹配闹出的 "chandelier ↔ chance" 误配——几乎都是"AI 写脚本、跑结果、人看数据发现问题"这样循环解决的。最花时间的从来不是写代码,而是**决定什么样的数据算"对"**。

纯静态 + GitHub Pages 的架构也让整个项目没有任何运维负担:push 即发布,现网就是仓库本身。

## 🔗 链接

- 🎧 Demo:**https://bigjeager.github.io/singtheword/**
- 🧑‍💻 源码:**https://github.com/bigjeager/singtheword**

音频与歌词版权归 Apple / 各版权方所有,项目仅供学习演示。
