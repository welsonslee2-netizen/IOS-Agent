"""
文件管理器：在 iOS 沙箱中安全读写文件
iOS App 只能访问自己的沙箱目录
"""
from __future__ import annotations

import os
from pathlib import Path


def _sandbox_root() -> Path:
    """获取 iOS 沙箱根目录（Documents）"""
    # iOS: ~/Documents  /  其他平台: 当前目录下的 sandbox/
    docs = Path.home() / "Documents"
    if docs.exists():
        return docs
    fallback = Path.home() / "ios_agent_sandbox"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback


class FileManager:
    """简单的文件读写工具，路径限制在沙箱内"""

    def __init__(self):
        self.root = _sandbox_root()

    def _safe_path(self, path: str) -> Path:
        """将路径解析到沙箱内，防止路径穿越"""
        target = (self.root / path).resolve()
        if not str(target).startswith(str(self.root)):
            raise PermissionError(f"路径越界：{path}")
        return target

    def read(self, path: str) -> str:
        target = self._safe_path(path)
        if not target.exists():
            return f"[错误] 文件不存在: {path}"
        return target.read_text(encoding="utf-8")

    def write(self, path: str, content: str) -> str:
        target = self._safe_path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        return f"✅ 已写入: {path} ({len(content)} 字符)"

    def list_dir(self, path: str = ".") -> str:
        target = self._safe_path(path)
        if not target.is_dir():
            return f"[错误] 不是目录: {path}"
        items = sorted(target.iterdir())
        lines = [f"{'📁' if p.is_dir() else '📄'} {p.name}" for p in items]
        return "\n".join(lines) or "(空目录)"
