# Vue 打字机效果实现详解：从 0 到可复用

> 适用代码：
>
> - `frontend/src/components/Welcome.vue`
> - `frontend/src/utils/TypeWriter.js`

这篇文章会带你完整拆解这个项目里的打字机效果：

- 文案从哪里来
- 状态怎么更新
- 为什么要用 `setTimeout`
- Vue 组件如何接入
- 如何扩展成“删除重打”“动态文案”等高级效果

---

## 1. 先看效果背后的核心思路

这个打字机不是“每次重新渲染整段文本”，而是：

1. 先准备多组文案（`segments`）
2. 维护一个“正在打到第几段、第几行、第几个字符”的状态机
3. 每隔 `charDelay` 毫秒追加一个字符
4. 每次变化通过 `onUpdate` 回调把最新状态发给 Vue
5. Vue 用响应式状态驱动模板渲染（并显示光标）

一句话总结：**定时器驱动状态机，状态机驱动 UI。**

---

## 2. Welcome.vue 中的接入方式（组件层）

### 2.1 响应式状态容器

```js
const typewriterState = reactive({
    lines: [],
    lineIndex: 0,
    playing: false
});
```

这 3 个字段含义：

- `lines`：当前屏幕上每一行已经打出来的文本
- `lineIndex`：当前正在输入的是第几行（用于显示光标）
- `playing`：是否处于播放状态

对应位置：`frontend/src/components/Welcome.vue:15`

### 2.2 创建打字机控制器

```js
const typewriterController = createTypewriter({
    segments: DEFAULT_TYPEWRITER_SEGMENTS,
    charDelay: 45,
    segmentPause: 3000,
    loop: true,
    onUpdate: ({ lines, lineIndex, playing }) => {
        typewriterState.lines = [...lines];
        typewriterState.lineIndex = lineIndex;
        typewriterState.playing = playing;
    }
});
```

重点：

- `segments`：文案来源
- `onUpdate`：桥梁函数，把工具层状态同步进 Vue
- `lines` 这里做了浅拷贝 `[...]`，避免直接引用内部数组

对应位置：`frontend/src/components/Welcome.vue:66`

### 2.3 生命周期控制

```js
onMounted(() => {
    typewriterController.start();
});

onBeforeUnmount(() => {
    typewriterController.stop();
});
```

原因：

- 进入页面后启动动画
- 离开页面及时清理定时器，防止内存泄漏和“幽灵更新”

对应位置：`frontend/src/components/Welcome.vue:257`

### 2.4 模板渲染与光标

```vue
<div v-for="(line, idx) in typewriterState.lines" :key="idx">
  {{ line }}
  <span v-if="typewriterState.playing && idx === typewriterState.lineIndex">▍</span>
</div>
```

逻辑很干净：

- 渲染所有已出现行
- 仅在当前输入行后面显示光标

对应位置：`frontend/src/components/Welcome.vue:272`

---

## 3. TypeWriter.js 核心实现（工具层）

### 3.1 文案数据结构

```js
export const DEFAULT_TYPEWRITER_SEGMENTS = [
  ['第一段第1行', '第一段第2行'],
  ['第二段第1行']
];
```

结构是 **二维数组**：

- 第一层：段落（segment）
- 第二层：该段中的多行文本（line）

对应位置：`frontend/src/utils/TypeWriter.js:1`

### 3.2 内部状态字段

`createTypewriter` 内部维护了这些关键变量：

- `segmentIndex`：当前段索引
- `lineIndex`：当前行索引
- `charIndex`：当前行字符索引
- `displayLines`：当前段已显示内容数组
- `running`：是否运行
- `typingTimer/pauseTimer`：输入与停顿两个定时器

这本质上就是一个轻量状态机。

对应位置：`frontend/src/utils/TypeWriter.js:25`

### 3.3 emit：向外同步状态

```js
const emit = (playing) => {
  onUpdate && onUpdate({
    lines: [...displayLines],
    segmentIndex,
    lineIndex,
    playing
  });
};
```

这里把内部状态“推”到外层组件。组件不关心内部细节，只消费结果。

对应位置：`frontend/src/utils/TypeWriter.js:33`

### 3.4 tick：逐字输入主循环

`tick` 是最核心的函数，建议按下面顺序理解：

1. 如果 `running=false`，直接返回
2. 取当前段、当前行
3. 如果 `charIndex < line.length`：
   - 追加 1 个字符到 `displayLines[lineIndex]`
   - `charIndex++`
   - `emit(true)`
   - `setTimeout(tick, charDelay)` 继续打字
4. 当前行打完后，切到下一行：
   - `lineIndex++`
   - `charIndex=0`
   - 如果还有下一行，继续 `tick`
5. 当前段全部打完后：
   - 等待 `segmentPause`
   - 调用 `advanceSegment()`

对应位置：`frontend/src/utils/TypeWriter.js:79`

### 3.5 advanceSegment：段落切换与循环

```js
const advanceSegment = () => {
  segmentIndex += 1;
  if (segmentIndex >= segments.length) {
    if (!loop) return stop();
    segmentIndex = 0;
  }
  prepareSegment();
  typingTimer = setTimeout(tick, charDelay);
};
```

这里决定“播完是否循环”。

对应位置：`frontend/src/utils/TypeWriter.js:113`

### 3.6 start / stop / reset 三个对外 API

- `start()`：重置并开始
- `stop()`：停止并清理 timer，同时 `emit(false)`
- `reset()`：停止 + 清空状态 + 发空状态

对应位置：`frontend/src/utils/TypeWriter.js:126`

---

## 4. 为什么这个实现是“工程友好”的

### 4.1 组件与逻辑解耦

- 组件只管渲染，不管定时器细节
- 打字机逻辑可在多个页面复用

### 4.2 避免 `setInterval` 常见坑

这里用的是“递归 `setTimeout`”，好处：

- 每次执行完再调度下一次，节奏更稳定
- 更容易在复杂分支下停止和切换

### 4.3 定时器清理完整

`clearTimers()` 同时清理输入与停顿两个 timer，避免残留异步任务。

---

## 5. 可直接复用的最小版模板

如果你想在新页面快速接入，最少需要这几步。

```vue
<script setup>
import { reactive, onMounted, onBeforeUnmount } from 'vue';
import { createTypewriter, DEFAULT_TYPEWRITER_SEGMENTS } from '@/utils/TypeWriter';

const state = reactive({ lines: [], lineIndex: 0, playing: false });

const ctrl = createTypewriter({
  segments: DEFAULT_TYPEWRITER_SEGMENTS,
  onUpdate: ({ lines, lineIndex, playing }) => {
    state.lines = [...lines];
    state.lineIndex = lineIndex;
    state.playing = playing;
  }
});

onMounted(() => ctrl.start());
onBeforeUnmount(() => ctrl.stop());
</script>

<template>
  <div v-for="(line, idx) in state.lines" :key="idx">
    {{ line }}<span v-if="state.playing && idx === state.lineIndex">▍</span>
  </div>
</template>
```

---

## 6. 常见问题与排查

### Q1：为什么看不到文字？

检查：

- `segments` 是否为空数组
- 是否在 `onMounted` 调用了 `start()`
- `onUpdate` 是否正确赋值到响应式对象

### Q2：页面离开后还在跑？

检查是否在 `onBeforeUnmount` 调了 `stop()`。

### Q3：光标位置不对？

确认模板条件是：`idx === lineIndex`，并且 `lineIndex` 来源于 `onUpdate`。

---

## 7. 进阶改造建议

你可以在现有实现上继续升级：

1. 删除动画：打完后反向删字，再切下一句
2. 动态文案：`segments` 从后端返回并支持热更新
3. 暂停/恢复：新增 `pause()` 和 `resume()`
4. 可配置速度：按行或按段设置不同 `charDelay`
5. 无障碍优化：为屏幕阅读器提供静态 fallback 文本

---

## 8. 一张“流程图”帮助你彻底记住

```text
mounted
  -> start()
      -> resetState()
      -> prepareSegment()
      -> tick()
          -> 追加字符 -> emit -> tick()
          -> 行结束 -> 下一行 -> tick()
          -> 段结束 -> pause -> advanceSegment()
          -> (loop ? 下一段 : stop)

beforeUnmount
  -> stop()
      -> clearTimers()
      -> emit(false)
```

---

## 9. 结语

这个打字机实现最大的价值不是“动画炫”，而是结构清晰：

- 工具层：可复用状态机
- 组件层：响应式渲染
- 生命周期：启动与清理明确

当你理解了这套分层，以后做轮播字幕、逐字字幕、教程引导字效，本质都可以复用这套模型。
