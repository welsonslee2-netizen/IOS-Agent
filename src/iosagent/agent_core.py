"""
Agent 核心：与 LLM 对话，解析并执行工具调用
支持 OpenAI / DeepSeek / 通义千问 等兼容 OpenAI 接口的服务
"""
from __future__ import annotations

import json
import os
from typing import AsyncIterator

import httpx


# ── 系统提示词 ──────────────────────────────────────────────────
SYSTEM_PROMPT = """你是一个运行在 iOS 设备上的智能 Agent。
你可以：
1. 执行 Python 代码（使用 run_python 工具）
2. 读写本地文件（使用 read_file / write_file 工具）
3. 发起 HTTP 请求（使用 http_get 工具）
4. 回答问题、分析数据

当用户要求执行代码时，请将代码包装在工具调用中，不要直接输出原始代码块。
回复请使用中文。"""


class AgentCore:
    """Agent 核心，管理对话历史和工具调用"""

    def __init__(self):
        self.api_key: str = os.environ.get("LLM_API_KEY", "")
        self.base_url: str = os.environ.get(
            "LLM_BASE_URL", "https://api.deepseek.com/v1"
        )
        self.model: str = os.environ.get("LLM_MODEL", "deepseek-chat")
        self.history: list[dict] = []
        self.tools = self._define_tools()

    # ─────────────────────────────────────────
    # 公开接口
    # ─────────────────────────────────────────

    async def chat(self, user_message: str) -> str:
        """发送消息并获取回复（含工具调用循环）"""
        self.history.append({"role": "user", "content": user_message})

        for _ in range(5):  # 最多 5 轮工具调用
            response = await self._call_llm()
            message = response["choices"][0]["message"]

            # 无工具调用 → 直接返回
            if not message.get("tool_calls"):
                reply = message.get("content", "")
                self.history.append({"role": "assistant", "content": reply})
                return reply

            # 处理工具调用
            self.history.append(message)
            tool_results = await self._execute_tool_calls(message["tool_calls"])
            self.history.extend(tool_results)

        return "Agent 达到最大工具调用轮次，请重新提问。"

    def reset(self):
        """清空对话历史"""
        self.history.clear()

    # ─────────────────────────────────────────
    # 内部方法
    # ─────────────────────────────────────────

    async def _call_llm(self) -> dict:
        """调用 LLM API"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": [{"role": "system", "content": SYSTEM_PROMPT}] + self.history,
            "tools": self.tools,
            "tool_choice": "auto",
            "temperature": 0.7,
        }

        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
            )
            resp.raise_for_status()
            return resp.json()

    async def _execute_tool_calls(self, tool_calls: list) -> list[dict]:
        """执行工具调用，返回结果消息列表"""
        from .code_runner import CodeRunner
        from .file_manager import FileManager

        runner = CodeRunner()
        fm = FileManager()
        results = []

        for call in tool_calls:
            name = call["function"]["name"]
            args = json.loads(call["function"].get("arguments", "{}"))
            tool_call_id = call["id"]

            try:
                if name == "run_python":
                    output = await runner.run(args["code"])
                elif name == "read_file":
                    output = fm.read(args["path"])
                elif name == "write_file":
                    output = fm.write(args["path"], args["content"])
                elif name == "http_get":
                    output = await self._http_get(args["url"])
                else:
                    output = f"未知工具: {name}"
            except Exception as e:
                output = f"工具执行出错: {e}"

            results.append({
                "role": "tool",
                "tool_call_id": tool_call_id,
                "content": str(output),
            })

        return results

    @staticmethod
    async def _http_get(url: str) -> str:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.get(url)
            return resp.text[:2000]  # 限制长度

    @staticmethod
    def _define_tools() -> list[dict]:
        return [
            {
                "type": "function",
                "function": {
                    "name": "run_python",
                    "description": "在 iOS 设备上执行 Python 代码，返回标准输出",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "code": {"type": "string", "description": "要执行的 Python 代码"},
                        },
                        "required": ["code"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "read_file",
                    "description": "读取本地文件内容",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "path": {"type": "string", "description": "文件路径"},
                        },
                        "required": ["path"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "write_file",
                    "description": "写入内容到本地文件",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "path": {"type": "string", "description": "文件路径"},
                            "content": {"type": "string", "description": "文件内容"},
                        },
                        "required": ["path", "content"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "http_get",
                    "description": "发起 HTTP GET 请求，获取网页或 API 数据",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "url": {"type": "string", "description": "请求的 URL"},
                        },
                        "required": ["url"],
                    },
                },
            },
        ]
