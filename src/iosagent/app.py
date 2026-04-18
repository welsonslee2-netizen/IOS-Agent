"""
iOS Agent - 主入口
使用 BeeWare/Toga 构建原生 iOS UI
"""
import toga
from toga.style import Pack
from toga.style.pack import COLUMN, ROW

from .agent_core import AgentCore
from .code_runner import CodeRunner


class iOSAgentApp(toga.App):
    """iOS Agent 主应用"""

    def startup(self):
        self.agent = AgentCore()
        self.runner = CodeRunner()

        # 主窗口
        self.main_window = toga.MainWindow(title=self.formal_name)

        # 构建 UI
        main_box = self._build_ui()
        self.main_window.content = main_box
        self.main_window.show()

    def _build_ui(self):
        """构建主界面"""
        outer_box = toga.Box(style=Pack(direction=COLUMN, padding=10))

        # ── 顶部标题 ──
        title = toga.Label(
            "🤖 iOS Agent",
            style=Pack(font_size=22, font_weight="bold", padding_bottom=8),
        )

        # ── 对话输出区 ──
        self.output_view = toga.MultilineTextInput(
            readonly=True,
            placeholder="Agent 输出将显示在这里...",
            style=Pack(flex=1, padding_bottom=8),
        )

        # ── 输入区 ──
        input_row = toga.Box(style=Pack(direction=ROW, padding_bottom=8))
        self.input_field = toga.TextInput(
            placeholder="输入指令或 Python 代码...",
            style=Pack(flex=1, padding_right=8),
        )
        send_btn = toga.Button(
            "发送",
            on_press=self.on_send,
            style=Pack(width=70),
        )
        input_row.add(self.input_field)
        input_row.add(send_btn)

        # ── 快捷操作按钮 ──
        actions_row = toga.Box(style=Pack(direction=ROW, padding_bottom=4))
        btn_run = toga.Button("▶ 运行代码", on_press=self.on_run_code, style=Pack(flex=1, padding_right=4))
        btn_clear = toga.Button("🗑 清空", on_press=self.on_clear, style=Pack(flex=1, padding_right=4))
        btn_info = toga.Button("ℹ 系统信息", on_press=self.on_sys_info, style=Pack(flex=1))
        actions_row.add(btn_run)
        actions_row.add(btn_clear)
        actions_row.add(btn_info)

        outer_box.add(title)
        outer_box.add(self.output_view)
        outer_box.add(input_row)
        outer_box.add(actions_row)

        return outer_box

    # ─────────────────────────────────────────
    # 事件处理
    # ─────────────────────────────────────────

    async def on_send(self, widget):
        """发送指令给 Agent"""
        user_input = self.input_field.value.strip()
        if not user_input:
            return
        self.input_field.value = ""
        self._append_output(f"👤 你: {user_input}")

        try:
            response = await self.agent.chat(user_input)
            self._append_output(f"🤖 Agent: {response}\n")
        except Exception as e:
            self._append_output(f"❌ 错误: {e}\n")

    async def on_run_code(self, widget):
        """直接运行输入框中的 Python 代码"""
        code = self.input_field.value.strip()
        if not code:
            self._append_output("⚠️ 请先在输入框中输入 Python 代码\n")
            return
        self.input_field.value = ""
        self._append_output(f"🐍 执行代码:\n{code}")

        result = await self.runner.run(code)
        self._append_output(f"📤 结果:\n{result}\n")

    async def on_sys_info(self, widget):
        """显示系统信息"""
        import platform
        import sys
        info = (
            f"🖥  平台: {platform.system()} {platform.release()}\n"
            f"🐍 Python: {sys.version}\n"
            f"📱 设备: {platform.machine()}\n"
        )
        self._append_output(info)

    def on_clear(self, widget):
        self.output_view.value = ""

    def _append_output(self, text: str):
        current = self.output_view.value or ""
        self.output_view.value = current + text + "\n"


def main():
    return iOSAgentApp("iOS Agent", "com.iosagent")
