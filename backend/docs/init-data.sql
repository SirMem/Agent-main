-- ============================================================
-- 最小化初始数据 - 用于测试对话功能
-- 执行前提: 已执行 init.sql 建表
-- ============================================================

USE `ai-agent`;

-- 1. 添加 API 配置（你的中转站）
INSERT INTO `ai_api` (`api_id`, `api_base_url`, `api_key`, `api_completions_path`, `api_embeddings_path`)
VALUES (
    'api_anthropic',
    'https://your-proxy-host.com',  -- 替换成你的中转站地址
    'sk-your-api-key-here',          -- 替换成你的 API Key
    '/v1/messages',                   -- Anthropic Messages API 路径
    NULL
)
ON DUPLICATE KEY UPDATE `api_base_url` = VALUES(`api_base_url`), `api_key` = VALUES(`api_key`);

-- 2. 添加模型配置
INSERT INTO `ai_model` (`model_id`, `api_id`, `model_name`, `model_type`)
VALUES (
    'model_claude',
    'api_anthropic',
    'claude-3-5-sonnet-20241022',  -- 替换成你实际使用的模型名
    'chat'
)
ON DUPLICATE KEY UPDATE `model_name` = VALUES(`model_name`);

-- 3. 添加客户端配置（这就是你请求时用的 clientId）
INSERT INTO `ai_client` (`client_id`, `client_type`, `client_role`, `model_id`, `model_name`, `client_name`, `client_desc`, `client_status`)
VALUES (
    'Claude',           -- 对应你请求的 clientId
    'chat',
    'assistant',
    'model_claude',
    'Claude',
    'Claude 对话客户端',
    'Claude 3.5 Sonnet',
    1
)
ON DUPLICATE KEY UPDATE `model_id` = VALUES(`model_id`), `client_status` = 1;

-- 4. 添加默认 Prompt（可选，如果不需要可以跳过）
INSERT INTO `ai_prompt` (`prompt_id`, `prompt_name`, `prompt_content`, `prompt_desc`)
VALUES (
    'prompt_default',
    '默认系统提示',
    'You are a helpful AI assistant.',
    '默认系统提示词'
)
ON DUPLICATE KEY UPDATE `prompt_content` = VALUES(`prompt_content`);

-- 5. 关联 Prompt 到客户端（可选）
INSERT INTO `ai_config` (`client_id`, `config_type`, `config_value`, `config_param`, `config_status`)
VALUES (
    'Claude',
    'prompt',
    'prompt_default',
    NULL,
    1
)
ON DUPLICATE KEY UPDATE `config_status` = 1;

