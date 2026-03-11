# 从 `Welcome.vue` 一键发起聊天：`setTask + 路由跳转` 的完整链路解析

> 这篇笔记专门回答一个常见疑问：
> `welcomeLaunchStore.setTask(...)` 看起来只是存了点数据，为什么跳转到 `/chat` 后就“自动发消息”了？

---

## 1. 先说结论

`welcomeLaunchStore.setTask(...)` **本身不会发请求**。
它只做一件事：把“启动任务”暂存在 Pinia store 里。

真正的请求发生在：

1. `router.push(/chat)` 跳转到聊天页；
2. `Chat.vue` 在 `onMounted` 时调用 `consumeWelcomeLaunchTask()`；
3. 这个函数从 store 取出任务，设置模型/MCP/RAG，再调用 `sendMessage()`；
4. `sendMessage()` 最终调用 `fetchComplete` 或 `fetchStream` 发起 HTTP 请求到后端。

一句话：**setTask 是“跨页面传参”，不是“直接请求后端”**。

---

## 2. 关键代码定位（你可以按这个顺序读）

### 2.1 Welcome 页：写入任务 + 跳转

文件：`frontend/src/components/Welcome.vue:194`

```js
welcomeLaunchStore.setTask({
  type: chat,
  prompt: action.prompt,
  sessionTitle: buildSessionTitle(action.prompt),
  clientId: selectedModel.value,
  mcpIdList: selectedMcpIds,
  ragTag
});

router.push(/chat);
```

这段逻辑是“发令枪”：
- `setTask`：把启动参数塞到全局 store
- `router.push(/chat)`：切到聊天页，让聊天页消费这份参数

---

### 2.2 Pinia store：任务只存一次，取走即清空

文件：`frontend/src/router/pinia.js:552`

```js
export const useWelcomeLaunchStore = defineStore(welcomeLaunch, {
  state: () => ({ task: null }),
  actions: {
    setTask(task) {
      this.task = task || null;
    },
    takeTask(type = ) {
      if (!this.task) return null;
      if (type && this.task.type !== type) return null;
      const task = this.task;
      this.task = null;
      return task;
    }
  }
});
```

设计亮点：
- `takeTask()` 是“消费型读取”（read-and-clear）
- 防止刷新/重复进入页面时重复触发同一个任务

---

### 2.3 路由：`/chat` 对应 `Chat.vue`

文件：`frontend/src/router/router.js:22`

```js
{
  path: /chat,
  name: chat,
  component: Chat
}
```

所以 `router.push(/chat)` 会挂载聊天组件。

---

### 2.4 Chat 页挂载后：自动消费 Welcome 任务

文件：`frontend/src/components/Chat.vue:531`

```js
onMounted(() => {
  Promise.all([fetchTags(), fetchModels(), fetchMcpTools()]).then(async () => {
    // ...
    await consumeWelcomeLaunchTask();
  });
});
```

核心在 `consumeWelcomeLaunchTask()`（`frontend/src/components/Chat.vue:484`）：

1. `const task = welcomeLaunchStore.takeTask(chat)`
2. 读取 `task.clientId` / `task.mcpIdList` / `task.ragTag`
3. 调用 `sendMessage({ content: task.prompt, forceNew: true, ... })`

这一步就是“自动发首条消息”的触发点。

---

### 2.5 真正请求后端：在 `sendMessage` 里

文件：`frontend/src/components/Chat.vue:712`

`sendMessage()` 会：
- 创建/校验会话
- 把用户消息塞到本地消息列表
- 根据模式调用：
  - `runComplete(...)`（普通请求）
  - `runStream(...)`（流式请求）

对应后端 API 在：
- `frontend/src/request/api.js:44` → `fetchComplete` → `POST /api/v1/ai/chat/complete`
- `frontend/src/request/api.js:71` → `fetchStream` → `POST /api/v1/ai/chat/stream`

所以，请求是 **Chat 页面发的**，不是 Welcome 页面直接发的。

---

## 3. 一张“时序图式”心智模型

```text
Welcome.vue
  ├─ setTask(task)           // 写入 Pinia
  └─ router.push(/chat)    // 跳转

Chat.vue (onMounted)
  ├─ fetchModels/fetchMcpTools...
  ├─ takeTask(chat)        // 从 Pinia 取任务并清空
  └─ sendMessage(...)
       ├─ ensureChatSession(...)
       ├─ buildChatRequestPayload(...)
       └─ fetchComplete/fetchStream(...)  // 真正HTTP请求
```

---

## 4. 这种实现的好处

1. **解耦**：Welcome 页不关心聊天页的请求细节；聊天页统一处理会话和发送逻辑。  
2. **复用**：所有发消息都走 `Chat.vue` 的同一条通道（校验、异常、UI状态一致）。  
3. **用户体验好**：点击欢迎卡片后直接进入聊天并自动发送，交互自然。  
4. **可扩展**：以后加更多欢迎动作，只要填 task 参数即可。

---

## 5. 你最容易误解的点（避坑）

- 误解 1：`setTask` 会请求后端。  
  - 实际：它只是写内存（Pinia state）。

- 误解 2：`router.push(/chat)` 会携带完整业务参数。  
  - 实际：参数不在 URL；真正参数存在 `welcomeLaunchStore.task`。

- 误解 3：任务会一直存在。  
  - 实际：`takeTask()` 取走后会清空，属于一次性消费。

---

## 6. 如果你要改造，这里是推荐方向

- 把 `task` 结构定义成统一类型（例如 TS interface 或 JSDoc），避免字段名漂移。
- 给 `consumeWelcomeLaunchTask()` 增加日志埋点：来源、task.key、发送耗时、失败原因。
- 若担心页面刷新导致任务丢失，可考虑“短暂持久化”（sessionStorage）+ 过期时间。
- 若后续要支持 deep link，可把部分参数放 query（如 `clientId`），其余仍走 store。

---

## 7. 总结

这套机制本质上是：

- **Pinia 作为跨页面临时总线（一次性任务）**
- **Router 负责页面切换**
- **目标页面在 mounted 生命周期里消费任务并执行真实请求**

所以你看到的 `setTask + push(/chat)`，不是“直接调用后端”，而是“把调用指令交给 Chat 页统一执行”。

