import tkinter as tk
from tkinter import scrolledtext, messagebox
import subprocess
import os


class GitHelper:
    def __init__(self, root):
        self.root = root
        self.root.title("Git Helper - Physics Sandbox")
        self.root.geometry("600x600")

        # Путь к проекту (автоматически определяется)
        self.project_path = os.path.dirname(os.path.abspath(__file__))

        # ===== СХЕМА ВЕТОК =====
        # origin (главный аккаунт) → только ветка main (финальный продукт)
        # wip   (запасной аккаунт) → только ветка wip  (черновик/сейф)
        self.MAIN_REMOTE = "https://github.com/pir0j0c232323/Physics_sandbox_for_school.git"
        self.WIP_REMOTE  = "https://github.com/pir0rip23/physics-sandbox-wip.git"

        # Заголовок
        title = tk.Label(root, text="🛠 Git Helper", font=("Arial", 16, "bold"))
        title.pack(pady=10)

        info = tk.Label(root, text="wip (локально) → сейф | main (origin) → финал",
                        font=("Arial", 9), fg="gray")
        info.pack()

        # Поле для сообщения коммита
        msg_frame = tk.Frame(root)
        msg_frame.pack(pady=5, padx=10, fill=tk.X)

        tk.Label(msg_frame, text="Сообщение:").pack(side=tk.LEFT)
        self.commit_msg = tk.Entry(msg_frame, width=50)
        self.commit_msg.pack(side=tk.LEFT, padx=5, fill=tk.X, expand=True)
        self.commit_msg.insert(0, "wip: обновление кода")

        # Кнопки
        btn_frame = tk.Frame(root)
        btn_frame.pack(pady=10)

        self.btn_pull = tk.Button(btn_frame, text="📥 Скачать", command=self.pull,
                                  bg="#90EE90", font=("Arial", 12, "bold"), width=15)
        self.btn_pull.pack(side=tk.LEFT, padx=5)

        self.btn_push_main = tk.Button(btn_frame, text="🚀 Отправить MAIN",
                                       command=self.push_main,
                                       bg="#87CEEB", font=("Arial", 12, "bold"), width=15)
        self.btn_push_main.pack(side=tk.LEFT, padx=5)

        self.btn_push_wip = tk.Button(btn_frame, text="📤 Отправить WIP",
                                      command=self.push_wip,
                                      bg="#FFB6C1", font=("Arial", 12, "bold"), width=15)
        self.btn_push_wip.pack(side=tk.LEFT, padx=5)

        # Лог операций
        log_frame = tk.Frame(root)
        log_frame.pack(pady=10, padx=10, fill=tk.BOTH, expand=True)

        tk.Label(log_frame, text="Лог операций:").pack(anchor=tk.W)
        self.log = scrolledtext.ScrolledText(log_frame, height=18, width=70,
                                             font=("Consolas", 10))
        self.log.pack(fill=tk.BOTH, expand=True)

        self.log_message("✅ Git Helper запущен")
        self.log_message(f"📁 Путь: {self.project_path}")

        # Первичная настройка remotes и веток
        self.setup_remotes()

    # ==================================================================
    # УТИЛИТЫ
    # ==================================================================
    def log_message(self, msg):
        self.log.insert(tk.END, msg + "\n")
        self.log.see(tk.END)
        self.root.update()

    def run_git(self, cmd, show_output=True):
        """Запускает команду git. Возвращает True если успех."""
        try:
            result = subprocess.run(cmd, shell=True, cwd=self.project_path,
                                    capture_output=True, text=True, encoding='utf-8',
                                    errors='replace')
            if show_output:
                if result.stdout:
                    for line in result.stdout.strip().splitlines():
                        self.log_message(f"   {line}")
                if result.stderr:
                    for line in result.stderr.strip().splitlines():
                        self.log_message(f"⚠️  {line}")
            return result.returncode == 0
        except Exception as e:
            self.log_message(f"❌ Ошибка запуска: {e}")
            return False

    def get_current_branch(self):
        result = subprocess.run("git branch --show-current", shell=True,
                                cwd=self.project_path, capture_output=True, text=True)
        return result.stdout.strip()

    # ==================================================================
    # НАСТРОЙКА REMOTES (один раз при старте)
    # ==================================================================
    def setup_remotes(self):
        self.log_message("\n🔧 Настройка remotes...")

        # origin → главный аккаунт
        if not self.run_git("git remote get-url origin", show_output=False):
            self.run_git(f"git remote add origin {self.MAIN_REMOTE}", show_output=False)
        else:
            self.run_git(f"git remote set-url origin {self.MAIN_REMOTE}", show_output=False)

        # wip → запасной аккаунт
        if not self.run_git("git remote get-url wip", show_output=False):
            self.run_git(f"git remote add wip {self.WIP_REMOTE}", show_output=False)
        else:
            self.run_git(f"git remote set-url wip {self.WIP_REMOTE}", show_output=False)

        # Гарантируем, что локально существуют обе ветки
        if not self.run_git("git rev-parse --verify wip", show_output=False):
            self.log_message("   Создаю локальную ветку wip...")
            self.run_git("git branch wip", show_output=False)

        if not self.run_git("git rev-parse --verify main", show_output=False):
            self.log_message("   Создаю локальную ветку main...")
            self.run_git("git branch main", show_output=False)

        # Всегда работаем в wip
        current = self.get_current_branch()
        if current != "wip":
            self.log_message(f"   Переключаюсь на рабочую ветку wip (был {current})...")
            self.run_git("git checkout wip", show_output=False)

        self.log_message("✅ Remotes настроены:")
        self.log_message(f"   origin → {self.MAIN_REMOTE}")
        self.log_message(f"   wip    → {self.WIP_REMOTE}")
        self.log_message(f"   локально: {self.get_current_branch()}\n")

    # ==================================================================
    # СКАЧАТЬ: забрать свежий main из origin и вмержить в локальный wip
    # ==================================================================
    def pull(self):
        self.log_message("\n🔄 Скачиваем изменения из origin/main...")
        self.log_message("→ Переключаемся на рабочую ветку wip")
        if not self.run_git("git checkout wip"):
            self.log_message("❌ Не удалось переключиться на wip!")
            return

        self.log_message("→ fetch origin...")
        if not self.run_git("git fetch origin"):
            self.log_message("❌ Не удалось скачать!")
            return

        self.log_message("→ merge origin/main в локальный wip...")
        if not self.run_git("git merge origin/main --no-edit"):
            self.log_message("⚠️  КОНФЛИКТ! Открой Godot и разреши вручную, потом коммить.")
            return

        self.log_message("✅ Скачивание завершено!\n")

    # ==================================================================
    # ОТПРАВИТЬ WIP: коммит в локальный wip + push в remote wip
    # ==================================================================
    def push_wip(self):
        msg = self.commit_msg.get().strip()
        if not msg:
            messagebox.showwarning("Внимание", "Введите сообщение коммита!")
            return

        self.log_message("\n📤 Отправляем в WIP (сейф)...")
        self.log_message("→ Переключаемся на wip")
        if not self.run_git("git checkout wip"):
            return

        self.log_message("→ Добавляем файлы...")
        self.run_git("git add .")

        self.log_message(f'→ Коммит: {msg}')
        if not self.run_git(f'git commit -m "{msg}"'):
            self.log_message("   (нечего коммитить — это нормально)")

        self.log_message("→ push в wip/wip...")
        if self.run_git("git push wip wip"):
            self.log_message("✅ WIP сохранён в запасной репе!\n")
        else:
            self.log_message("⚠️  Push не удался — проверь доступ к wip репе\n")

    # ==================================================================
    # ОТПРАВИТЬ MAIN: слить wip в локальный main + push в origin/main
    # ==================================================================
    def push_main(self):
        msg = self.commit_msg.get().strip()
        if not msg:
            messagebox.showwarning("Внимание", "Введите сообщение коммита!")
            return

        answer = messagebox.askyesno(
            "Отправить в MAIN",
            "Финальный продукт уйдёт в главную репу.\n"
            "Убедись, что прошла регрессия!\n\nПродолжить?"
        )
        if not answer:
            return

        self.log_message("\n🚀 Отправляем в MAIN (финал)...")

        # Сначала гарантируем, что рабочая версия сохранена в wip
        self.log_message("→ Сохраняю текущее в wip...")
        self.run_git("git checkout wip")
        self.run_git("git add .")
        self.run_git(f'git commit -m "{msg}"')
        self.run_git("git push wip wip")

        # Merge wip → main
        self.log_message("→ Переключаюсь на main...")
        if not self.run_git("git checkout main"):
            self.log_message("❌ Не удалось переключиться на main!")
            return

        self.log_message("→ Слияние wip в main...")
        if not self.run_git("git merge wip --no-edit"):
            self.log_message("❌ Слияние не удалось!")
            self.run_git("git checkout wip")
            return

        self.log_message("→ push в origin/main...")
        if self.run_git("git push origin main"):
            self.log_message("✅ MAIN обновлён в главной репе!\n")
        else:
            self.log_message("⚠️  Push не удался — проверь доступ к origin\n")

        # Возвращаемся на рабочую ветку
        self.log_message("→ Возвращаюсь на wip...")
        self.run_git("git checkout wip")


if __name__ == "__main__":
    root = tk.Tk()
    app = GitHelper(root)
    root.mainloop()