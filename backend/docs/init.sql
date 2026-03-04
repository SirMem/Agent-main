-- ============================================================
-- Dasi Agent 数据库初始化脚本
-- 数据库: ai-agent (MySQL 8.0)
-- ============================================================

CREATE DATABASE IF NOT EXISTS `ai-agent` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ai-agent`;

-- ==================== 用户表 ====================
CREATE TABLE IF NOT EXISTS `user` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `username`    VARCHAR(64)  NOT NULL COMMENT '用户名',
    `password`    VARCHAR(128) NOT NULL COMMENT '密码',
    `role`        VARCHAR(32)  NOT NULL DEFAULT 'user' COMMENT '角色: user/admin',
    `user_status` INT          NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ==================== API 接口表 ====================
CREATE TABLE IF NOT EXISTS `ai_api` (
    `id`                   BIGINT       NOT NULL AUTO_INCREMENT,
    `api_id`               VARCHAR(64)  NOT NULL COMMENT 'API 标识',
    `api_base_url`         VARCHAR(256) NOT NULL COMMENT 'API 基础地址',
    `api_key`              VARCHAR(256) NOT NULL COMMENT 'API 密钥',
    `api_completions_path` VARCHAR(128) DEFAULT NULL COMMENT '对话补全路径',
    `api_embeddings_path`  VARCHAR(128) DEFAULT NULL COMMENT '向量嵌入路径',
    `create_time`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_api_id` (`api_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='API 接口配置表';

-- ==================== 模型表 ====================
CREATE TABLE IF NOT EXISTS `ai_model` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `model_id`    VARCHAR(64)  NOT NULL COMMENT '模型标识',
    `api_id`      VARCHAR(64)  NOT NULL COMMENT '关联 API 标识',
    `model_name`  VARCHAR(128) NOT NULL COMMENT '模型名称',
    `model_type`  VARCHAR(32)  NOT NULL COMMENT '模型类型',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_model_id` (`model_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='模型配置表';

-- ==================== Advisor 表 ====================
CREATE TABLE IF NOT EXISTS `ai_advisor` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT,
    `advisor_id`    VARCHAR(64)  NOT NULL COMMENT 'Advisor 标识',
    `advisor_name`  VARCHAR(128) NOT NULL COMMENT 'Advisor 名称',
    `advisor_type`  VARCHAR(32)  DEFAULT NULL COMMENT 'Advisor 类型',
    `advisor_desc`  VARCHAR(512) DEFAULT NULL COMMENT '描述',
    `advisor_order` INT          DEFAULT 0 COMMENT '排序',
    `advisor_param` TEXT         DEFAULT NULL COMMENT '参数配置(JSON)',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_advisor_id` (`advisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Advisor 配置表';

-- ==================== Prompt 表 ====================
CREATE TABLE IF NOT EXISTS `ai_prompt` (
    `id`             BIGINT       NOT NULL AUTO_INCREMENT,
    `prompt_id`      VARCHAR(64)  NOT NULL COMMENT 'Prompt 标识',
    `prompt_name`    VARCHAR(128) NOT NULL COMMENT 'Prompt 名称',
    `prompt_content` TEXT         DEFAULT NULL COMMENT 'Prompt 内容',
    `prompt_desc`    VARCHAR(512) DEFAULT NULL COMMENT '描述',
    `create_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_prompt_id` (`prompt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Prompt 配置表';

-- ==================== MCP 工具表 ====================
CREATE TABLE IF NOT EXISTS `ai_mcp` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `mcp_id`      VARCHAR(64)  NOT NULL COMMENT 'MCP 标识',
    `mcp_name`    VARCHAR(128) NOT NULL COMMENT 'MCP 名称',
    `mcp_type`    VARCHAR(32)  NOT NULL COMMENT '类型: sse/stdio',
    `mcp_config`  TEXT         DEFAULT NULL COMMENT '配置(JSON)',
    `mcp_desc`    VARCHAR(512) DEFAULT NULL COMMENT '描述',
    `mcp_timeout` INT          DEFAULT 60 COMMENT '超时秒数',
    `mcp_chat`    INT          DEFAULT 0 COMMENT '是否可用于聊天: 0-否, 1-是',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_mcp_id` (`mcp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MCP 工具配置表';

-- ==================== 客户端表 ====================
CREATE TABLE IF NOT EXISTS `ai_client` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT,
    `client_id`     VARCHAR(64)  NOT NULL COMMENT '客户端标识',
    `client_type`   VARCHAR(32)  NOT NULL COMMENT '类型: chat/work',
    `client_role`   VARCHAR(64)  DEFAULT NULL COMMENT '角色',
    `model_id`      VARCHAR(64)  NOT NULL COMMENT '关联模型标识',
    `model_name`    VARCHAR(128) DEFAULT NULL COMMENT '模型名称',
    `client_name`   VARCHAR(128) NOT NULL COMMENT '客户端名称',
    `client_desc`   VARCHAR(512) DEFAULT NULL COMMENT '描述',
    `client_status` INT          NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_client_id` (`client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户端配置表';

-- ==================== 客户端关联配置表 ====================
CREATE TABLE IF NOT EXISTS `ai_config` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT,
    `client_id`     VARCHAR(64)  NOT NULL COMMENT '客户端标识',
    `config_type`   VARCHAR(32)  NOT NULL COMMENT '配置类型: prompt/advisor/mcp',
    `config_value`  VARCHAR(128) NOT NULL COMMENT '配置值(关联 ID)',
    `config_param`  TEXT         DEFAULT NULL COMMENT '参数配置(JSON)',
    `config_status` INT          NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_config` (`client_id`, `config_type`, `config_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户端关联配置表';

-- ==================== Agent 表 ====================
CREATE TABLE IF NOT EXISTS `ai_agent` (
    `id`           BIGINT       NOT NULL AUTO_INCREMENT,
    `agent_id`     VARCHAR(64)  NOT NULL COMMENT 'Agent 标识',
    `agent_name`   VARCHAR(128) NOT NULL COMMENT 'Agent 名称',
    `agent_type`   VARCHAR(32)  NOT NULL COMMENT '类型: loop/step',
    `agent_desc`   VARCHAR(512) DEFAULT NULL COMMENT '描述',
    `agent_status` INT          NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
    `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent 配置表';

-- ==================== 工作流表 ====================
CREATE TABLE IF NOT EXISTS `ai_flow` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `agent_id`    VARCHAR(64)  NOT NULL COMMENT '关联 Agent 标识',
    `client_id`   VARCHAR(64)  NOT NULL COMMENT '关联客户端标识',
    `client_role` VARCHAR(64)  DEFAULT NULL COMMENT '角色',
    `flow_prompt` TEXT         DEFAULT NULL COMMENT '流程 Prompt',
    `flow_seq`    INT          NOT NULL DEFAULT 0 COMMENT '执行顺序',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_flow` (`agent_id`, `client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent 工作流配置表';

-- ==================== 定时任务表 ====================
CREATE TABLE IF NOT EXISTS `ai_task` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `task_id`     VARCHAR(64)  NOT NULL COMMENT '任务标识',
    `agent_id`    VARCHAR(64)  NOT NULL COMMENT '关联 Agent 标识',
    `task_cron`   VARCHAR(64)  NOT NULL COMMENT 'Cron 表达式',
    `task_desc`   VARCHAR(512) DEFAULT NULL COMMENT '描述',
    `task_param`  TEXT         DEFAULT NULL COMMENT '任务参数(JSON)',
    `task_status` INT          NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用, 1-启用',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='定时任务表';

-- ==================== 统计表 ====================
CREATE TABLE IF NOT EXISTS `ai_stat` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT,
    `stat_date`     DATE         NOT NULL COMMENT '统计日期',
    `stat_category` VARCHAR(32)  NOT NULL COMMENT '统计分类',
    `stat_key`      VARCHAR(64)  NOT NULL COMMENT '统计键',
    `stat_value`    VARCHAR(128) NOT NULL COMMENT '统计值',
    `stat_count`    BIGINT       NOT NULL DEFAULT 0 COMMENT '计数',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_stat` (`stat_date`, `stat_category`, `stat_key`, `stat_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='统计表';

-- ==================== 会话表 ====================
CREATE TABLE IF NOT EXISTS `session` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT,
    `session_id`    VARCHAR(64)  NOT NULL COMMENT '会话标识',
    `session_user`  VARCHAR(64)  NOT NULL COMMENT '用户',
    `session_title` VARCHAR(256) DEFAULT NULL COMMENT '会话标题',
    `session_type`  VARCHAR(32)  NOT NULL COMMENT '类型: chat/work',
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_session_id` (`session_id`),
    KEY `idx_session_user` (`session_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会话表';

-- ==================== 消息表 ====================
CREATE TABLE IF NOT EXISTS `message` (
    `id`              BIGINT       NOT NULL AUTO_INCREMENT,
    `session_id`      VARCHAR(64)  NOT NULL COMMENT '会话标识',
    `message_content` MEDIUMTEXT   DEFAULT NULL COMMENT '消息内容',
    `message_role`    VARCHAR(32)  NOT NULL COMMENT '角色: user/assistant/system',
    `message_type`    VARCHAR(32)  NOT NULL COMMENT '类型: chat/work',
    `message_seq`     INT          NOT NULL DEFAULT 0 COMMENT '消息序号',
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_session_type` (`session_id`, `message_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息表';

-- ==================== 初始数据 ====================
-- 默认管理员账号 (密码需要你自己用 BCrypt 加密后替换)
INSERT INTO `user` (`username`, `password`, `role`, `user_status`)
VALUES ('admin', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36Zu4MkzQ3YVJ5VxLiMHx2e', 'admin', 1)
ON DUPLICATE KEY UPDATE `id` = `id`;

