# Docker Compose 网络避坑指南：让 Backend / Frontend / MCP 真正互通

最近在部署 `docker-compose.yml`（backend + frontend）和 `docker-compose-mcp.yml`（MCP 服务）时，最容易踩的坑就是：**容器都启动了，但服务互相访问不到**。  
这篇文章用实战视角讲清楚 Docker Compose 的 network 机制，以及如何一次性配对成功。

---

## 一、先说结论（给赶时间的你）

如果你要让两个 compose 文件里的容器互通，推荐统一使用同一个外部网络：

```yml
networks:
  ai-agent:
    external: true
```

并且所有服务都挂到 `ai-agent`：

```yml
services:
  backend:
    networks:
      - ai-agent
```

最后确保网络存在：

```bash
docker network create ai-agent
```

---

## 二、为什么“改了同名 network 还是不通”？

很多人会把 `docker-compose.yml` 里的 `agent-net` 改成 `ai-agent`，以为就可以互通。  
但实际可能还是不通，原因是：

- Compose 默认会创建**项目级网络**，常见形式是：`<project>_<network>`
- 两个目录下分别执行 compose，`project` 名常常不同
- 即使你都写 `ai-agent`，实际可能是两个不同网络，比如：
  - `app1_ai-agent`
  - `app2_ai-agent`

所以容器不在同一个二层网络，自然不能直接用容器名互相解析访问。

---

## 三、Docker Compose 网络机制（够用版）

你可以把它理解成三层：

1. **网络对象（Network）**  
   Docker 里的真实网络实例，例如 `ai-agent`。

2. **服务加入网络**  
   每个 service 可以加入 1 个或多个网络。

3. **内置 DNS**  
   同一网络里的容器，可通过服务名互相访问（例如 `http://mcp-server-bocha:9005`）。

关键点：**DNS 解析只在同一 Docker network 内生效**。

---

## 四、正确配置范式

### 1）在 `docker-compose.yml`（backend/frontend）中使用外部网络

```yml
services:
  backend:
    networks:
      - ai-agent
  frontend:
    networks:
      - ai-agent

networks:
  ai-agent:
    external: true
```

### 2）在 `docker-compose-mcp.yml`（MCP）中保持同样声明

```yml
services:
  mcp-server-bocha:
    networks:
      - ai-agent

networks:
  ai-agent:
    external: true
```

### 3）启动前创建网络

```bash
docker network create ai-agent
```

如果网络已存在会提示冲突，可忽略或先 `docker network ls` 查看。

---

## 五、如何验证是否真的在同一网段

### 1）看网络里有哪些容器

```bash
docker network inspect ai-agent
```

确认 backend / frontend / mcp 容器都在 `Containers` 列表里。

### 2）容器内连通性测试

进入 backend 容器后测试：

```bash
curl http://mcp-server-bocha:9005/actuator/health
```

若能返回结果，说明 DNS 和网络互通都正常。

---

## 六、常见坑位清单

- 只改了 network 名字，没加 `external: true`
- 忘了先创建外部网络 `ai-agent`
- 在不同目录执行 compose，project 名不同导致网络被自动前缀化
- backend 配置里仍然写 `localhost:9005`（容器内 `localhost` 指自己）
- 端口映射正常但容器内互访地址写错（应优先用服务名）

---

## 七、实践建议（生产更稳）

1. 给跨 compose 的共享网络统一命名（如 `ai-agent`）
2. 统一用 `external: true`，避免隐式网络
3. 服务间调用优先用容器 DNS 名，不依赖宿主机端口
4. 每次调整后都执行 `docker network inspect` 做验收

---

## 八、总结

这类问题的本质不是“容器有没有起来”，而是“容器是否在同一个 Docker 网络并可通过 DNS 互相解析”。  
把共享网络改成 `external: true` + 显式创建 + 统一挂载，你的 backend / frontend / MCP 才能真正做到开箱互通。

