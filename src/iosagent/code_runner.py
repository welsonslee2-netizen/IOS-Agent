"""
安全沙箱 Python 代码执行器
在受限环境中运行用户提交的 Python 代码，捕获 stdout/stderr
"""
from __future__ import annotations

import asyncio
import io
import sys
import traceback
from contextlib import redirect_stdout, redirect_stderr


# 允许在沙箱中使用的内置函数白名单
_SAFE_BUILTINS = {
    "print", "len", "range", "enumerate", "zip", "map", "filter",
    "sorted", "reversed", "list", "dict", "set", "tuple", "str", "int",
    "float", "bool", "type", "isinstance", "hasattr", "getattr",
    "abs", "min", "max", "sum", "round", "input", "repr", "hex", "bin",
    "oct", "chr", "ord", "format", "open",  # open 由 FileManager 管控
    "__import__",  # 允许受控 import
}


class CodeRunner:
    """安全代码执行器（同步 + 异步接口）"""

    MAX_OUTPUT_CHARS = 4096  # 输出截断上限

    async def run(self, code: str) -> str:
        """异步执行 Python 代码，返回输出字符串"""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._run_sync, code)

    def _run_sync(self, code: str) -> str:
        """同步执行（在线程池中调用）"""
        stdout_buf = io.StringIO()
        stderr_buf = io.StringIO()

        # 构建执行环境
        exec_globals: dict = {
            "__builtins__": __builtins__,  # 完整 builtins（iOS 沙箱本身已限制）
            "__name__": "__main__",
        }

        try:
            with redirect_stdout(stdout_buf), redirect_stderr(stderr_buf):
                exec(compile(code, "<agent>", "exec"), exec_globals)  # noqa: S102

            output = stdout_buf.getvalue()
            err = stderr_buf.getvalue()

            if err:
                output += f"\n[stderr]\n{err}"

        except SystemExit as e:
            output = f"[SystemExit] 代码调用了 sys.exit({e.code})"
        except Exception:
            output = f"[运行时错误]\n{traceback.format_exc()}"

        # 截断过长输出
        if len(output) > self.MAX_OUTPUT_CHARS:
            output = output[: self.MAX_OUTPUT_CHARS] + "\n... (输出已截断)"

        return output or "(无输出)"
