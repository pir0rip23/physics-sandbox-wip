import tkinter as tk
from tkinter import scrolledtext, messagebox
import subprocess
import os


class GitHelper:
    def __init__(self, root):
        self.root = root
        self.root.title("Git Helper - Physics Sandbox")
        self.root.geometry("600x500")

        # Путь к проекту (автоматически определяется)
        self.project_path = os.path.dirname(os.path.abspath(__file__))

        # Заголовок
        title = tk.Label(root, text="️ Git Helper", font=("Arial", 16, "bold"))
        title.pack(pady=10)

        # Поле для сообщения коммита
        msg_frame = tk.Frame(root)
        msg_frame.pack(pady=5, padx=10, fill=tk.X)

        tk.Label(msg_frame, text="Сообщение коммита:").pack(side=tk.LEFT)
        self.commit_msg = tk.Entry(msg_frame, width=50)
        self.commit_msg.pack(side=tk.LEFT, padx=5, fill=tk.X, expand=True)
        self.commit_msg.insert(0, "wip: обновление кода")

        # Кнопки
        btn_frame = tk.Frame(root)
        btn_frame.pack(pady=10)

        self.btn_pull = tk.Button(btn_frame, text="📥 Скачать", command=self.pull,
                                  bg="#90EE90", font=("Arial", 12, "bold"), width=15)
        self.btn_pull.pack(side=tk.LEFT, padx=5)

        self.btn_push_main = tk.Button(btn_frame, text=" Отправить MAIN",
                                       command=lambda: self.push("main"),
                                       bg="#87CEEB", font=("Arial", 12, "bold"), width=15)
        self.btn_push_main.pack(side=tk.LEFT, padx=5)

        self.btn_push_wip = tk.Button(btn_frame, text="📤 Отправить WIP",
                                      command=lambda: self.push("wip"),
                                      bg="#FFB6C1", font=("Arial", 12, "bold"), width=15)
        self.btn_push_wip.pack(side=tk.LEFT, padx=5)

        # Лог операций
        log_frame = tk.Frame(root)
        log_frame.pack(pady=10, padx=10, fill=tk.BOTH, expand=True)

        tk.Label(log_frame, text="Лог операций:").pack(anchor=tk.W)
        self.log = scrolledtext.ScrolledText(log_frame, height=15, width=70,
                                             font=("Consolas", 10))
        self.log.pack(fill=tk.BOTH, expand=True)

        self.log_message("✅ Приложение готово к работе!")
        self.log_message(f"📁 Путь к проекту: {self.project_path}")

    def log_message(self, msg):
        self.log.insert(tk.END, msg + "\n")
        self.log.see(tk.END)
        self.root.update()

    def run_git_command(self, cmd):
        try:
            result = subprocess.run(cmd, shell=True, cwd=self.project_path,
                                    capture_output=True, text=True, encoding='utf-8')
            if result.stdout:
                self.log_message(result.stdout.strip())
            if result.stderr:
                self.log_message(f"⚠️ {result.stderr.strip()}")
            return result.returncode == 0
        except Exception as e:
            self.log_message(f"❌ Ошибка: {e}")
            return False

    def pull(self):
        self.log_message("\n🔄 Скачиваем изменения...")
        self.run_git_command("git pull origin main")
        self.log_message("✅ Скачивание завершено!\n")

    def push(self, branch):
        msg = self.commit_msg.get().strip()
        if not msg:
            messagebox.showwarning("Внимание", "Введите сообщение коммита!")
            return

        self.log_message(f"\n Отправляем в {branch.upper()}...")

        # Переключаемся на нужную ветку
        self.log_message(f"→ Переключаемся на ветку {branch}...")
        if not self.run_git_command(f"git checkout {branch}"):
            self.log_message("❌ Не удалось переключить ветку!")
            return

        # Добавляем изменения
        self.log_message("→ Добавляем файлы...")
        self.run_git_command("git add .")

        # Коммит
        self.log_message(f"→ Коммит: {msg}")
        if not self.run_git_command(f'git commit -m "{msg}"'):
            self.log_message("⚠️ Возможно, нечего коммитить (нет изменений)")

        # Пуш
        if branch == "main":
            self.log_message("→ Пушим в origin/main...")
            self.run_git_command("git push origin main")
        else:
            self.log_message("→ Пушим в wip/wip...")
            self.run_git_command("git push wip wip")

        self.log_message(f"✅ Отправка в {branch.upper()} завершена!\n")


if __name__ == "__main__":
    root = tk.Tk()
    app = GitHelper(root)
    root.mainloop()