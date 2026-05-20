import tkinter as tk
from tkinter import messagebox, ttk
import pyodbc

# ─────────────────────────────────────────
#  DATABASE CONNECTION
# ─────────────────────────────────────────
def get_connection():
    return pyodbc.connect(
        "DRIVER={SQL Server};"
        "SERVER=YOUR_SERVER_NAME;"
        "DATABASE=Factory;"
        "Trusted_Connection=yes;"
    )

# ─────────────────────────────────────────
#  MAIN APPLICATION
# ─────────────────────────────────────────
class FactoryApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Factory Security Demo")
        self.geometry("1024x480")
        self.resizable(False, False)
        self.configure(bg="#1a1a2e")

        # Style
        self.style = ttk.Style(self)
        self.style.theme_use("clam")
        self.style.configure("TLabel", background="#1a1a2e", foreground="#e0e0e0", font=("Courier New", 10))
        self.style.configure("Header.TLabel", background="#1a1a2e", foreground="#00d4ff", font=("Courier New", 14, "bold"))
        self.style.configure("Sub.TLabel", background="#1a1a2e", foreground="#888888", font=("Courier New", 9))

        self.frames = {}
        for F in (LoginPage, DashboardPage):
            frame = F(parent=self, controller=self)
            self.frames[F] = frame
            frame.place(relwidth=1, relheight=1)

        self.show_frame(LoginPage)

    def show_frame(self, page_class):
        frame = self.frames[page_class]
        frame.tkraise()


# ─────────────────────────────────────────
#  PAGE 1 – LOGIN
# ─────────────────────────────────────────
class LoginPage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg="#1a1a2e")
        self.controller = controller

        # ── Title ──
        tk.Label(self, text="FACTORY SYSTEM", bg="#1a1a2e",
                 fg="#00d4ff", font=("Courier New", 16, "bold")).pack(pady=(30, 2))
        tk.Label(self, text="Employee Login Portal", bg="#1a1a2e",
                 fg="#555577", font=("Courier New", 9)).pack(pady=(0, 20))

        # ── Card frame ──
        card = tk.Frame(self, bg="#16213e", bd=0, relief="flat",
                        highlightthickness=1, highlightbackground="#00d4ff")
        card.pack(padx=60, pady=10, fill="x")

        tk.Label(card, text="Username", bg="#16213e", fg="#aaaaaa",
                 font=("Courier New", 9)).pack(anchor="w", padx=20, pady=(18, 2))
        self.username = tk.Entry(card, font=("Courier New", 11), bg="#0f3460",
                                 fg="white", insertbackground="white",
                                 relief="flat", bd=6)
        self.username.pack(fill="x", padx=20, pady=(0, 10))

        tk.Label(card, text="Password", bg="#16213e", fg="#aaaaaa",
                 font=("Courier New", 9)).pack(anchor="w", padx=20, pady=(0, 2))
        self.password = tk.Entry(card, show="*", font=("Courier New", 11),
                                 bg="#0f3460", fg="white",
                                 insertbackground="white", relief="flat", bd=6)
        self.password.pack(fill="x", padx=20, pady=(0, 18))

        # ── Status label ──
        self.status = tk.Label(self, text="", bg="#1a1a2e",
                               fg="#ff4444", font=("Courier New", 9))
        self.status.pack(pady=4)

        # ── Buttons ──
        btn_frame = tk.Frame(self, bg="#1a1a2e")
        btn_frame.pack(pady=8)

        tk.Button(btn_frame, text="⚠  Vulnerable Login",
                  bg="#8b0000", fg="white", activebackground="#ff2222",
                  font=("Courier New", 10, "bold"), relief="flat",
                  padx=14, pady=8, cursor="hand2",
                  command=self.bad_login).pack(side="left", padx=10)

        tk.Button(btn_frame, text="🔐  Secure Login",
                  bg="#006400", fg="white", activebackground="#00aa00",
                  font=("Courier New", 10, "bold"), relief="flat",
                  padx=14, pady=8, cursor="hand2",
                  command=self.secure_login).pack(side="left", padx=10)

        # ── Hint ──
        tk.Label(self,
                 text='Injection hint:  username = \'  OR \'1\'=\'1\'--',
                 bg="#1a1a2e", fg="#444466",
                 font=("Courier New", 8, "italic")).pack(pady=(12, 0))
        tk.Label(self,
                 text='Catastrophic hint:  username = \'  ; DROP TABLE Users--',
                 bg="#1a1a2e", fg="#663333",
                 font=("Courier New", 8, "italic")).pack()

    # ── VULNERABLE LOGIN ──
    def bad_login(self):
        user = self.username.get()
        pwd  = self.password.get()

        try:
            conn   = get_connection()
            cursor = conn.cursor()

            # ❌ STRING CONCATENATION → SQL INJECTION POSSIBLE
            query = (
                f"SELECT * FROM Users "
                f"WHERE username='{user}' AND password='{pwd}'"
            )
            self.status.config(text=f"Executing: {query[:70]}…", fg="#ffaa00")
            self.update()

            # Detect DROP / catastrophic payload
            if "drop" in user.lower() or "drop" in pwd.lower():
                try:
                    cursor.execute(query)
                    conn.commit()
                except Exception:
                    pass
                conn.close()
                self._show_catastrophe()
                return

            cursor.execute(query)
            row = cursor.fetchone()
            conn.close()

            if row:
                self.status.config(text="⚠ Access granted via VULNERABLE login!", fg="#ff8800")
                self.controller.show_frame(DashboardPage)
                self.controller.frames[DashboardPage].set_user(row[0] if row else "Unknown")
            else:
                self.status.config(text="Login failed.", fg="#ff4444")

        except Exception as e:
            self.status.config(text=f"DB Error: {e}", fg="#ff4444")

    # ── CATASTROPHIC RESULT DIALOG ──
    def _show_catastrophe(self):
        win = tk.Toplevel(self.controller)
        win.title("💀 CATASTROPHIC BREACH")
        win.geometry("460x320")
        win.configure(bg="#1a0000")
        win.grab_set()

        tk.Label(win, text="💀  DATABASE DESTROYED",
                 bg="#1a0000", fg="#ff0000",
                 font=("Courier New", 15, "bold")).pack(pady=(24, 6))

        msg = (
            "SQL Injection payload detected:\n\n"
            "  '; DROP TABLE Users --\n\n"
            "The Users table has been DROPPED.\n"
            "All login credentials are gone.\n"
            "The application can no longer authenticate.\n\n"
            "This is a real-world catastrophic consequence\n"
            "of unsanitized string concatenation in SQL."
        )
        tk.Label(win, text=msg, bg="#1a0000", fg="#ff6666",
                 font=("Courier New", 9), justify="left").pack(padx=30)

        tk.Button(win, text="Close", bg="#550000", fg="white",
                  font=("Courier New", 10), relief="flat",
                  command=win.destroy).pack(pady=16)

    # ── SECURE LOGIN ──
    def secure_login(self):
        user = self.username.get()
        pwd  = self.password.get()

        try:
            conn   = get_connection()
            cursor = conn.cursor()

            # ✅ PARAMETERIZED QUERY — injection impossible
            cursor.execute(
                "SELECT * FROM Users WHERE username=? AND password=?",
                (user, pwd)
            )
            row = cursor.fetchone()
            conn.close()

            if row:
                self._show_security_measures()
                self.status.config(text="🔐 Secure login successful!", fg="#00ff88")
                self.controller.show_frame(DashboardPage)
                self.controller.frames[DashboardPage].set_user(row[0] if row else "Unknown")
            else:
                self.status.config(text="Login failed — invalid credentials.", fg="#ff4444")

        except Exception as e:
            self.status.config(text=f"DB Error: {e}", fg="#ff4444")

    def _show_security_measures(self):
        win = tk.Toplevel(self.controller)
        win.title("Security Measures Active")
        win.geometry("440x320")
        win.configure(bg="#001a0e")
        win.grab_set()

        tk.Label(win, text="🔐  SECURE LOGIN ACTIVE",
                 bg="#001a0e", fg="#00ff88",
                 font=("Courier New", 13, "bold")).pack(pady=(20, 8))

        measures = (
            "Protections applied to prevent SQL Injection:\n\n"
            "  ✔  Parameterized queries (? placeholders)\n"
            "      User input is NEVER concatenated into SQL.\n\n"
            "  ✔  Input treated as DATA, not executable code\n"
            "      The driver binds values after parsing SQL.\n\n"
            "  ✔  No string formatting / f-strings in queries\n"
            "      Eliminates the attack surface entirely.\n\n"
            "  ✔  Any injection payload is stored literally\n"
            "      e.g. the string \"' OR '1'='1'\" won't match."
        )
        tk.Label(win, text=measures, bg="#001a0e", fg="#88ffcc",
                 font=("Courier New", 9), justify="left").pack(padx=28)

        tk.Button(win, text="Proceed to Dashboard →",
                  bg="#005522", fg="white",
                  font=("Courier New", 10), relief="flat",
                  command=win.destroy).pack(pady=14)


# ─────────────────────────────────────────
#  PAGE 2 – DASHBOARD  (SP3 RESULTS)
# ─────────────────────────────────────────
class DashboardPage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg="#1a1a2e")
        self.controller = controller

        tk.Label(self, text="FACTORY DASHBOARD", bg="#1a1a2e",
                 fg="#00d4ff", font=("Courier New", 15, "bold")).pack(pady=(28, 4))

        self.welcome = tk.Label(self, text="", bg="#1a1a2e",
                                fg="#888888", font=("Courier New", 9))
        self.welcome.pack()

        # ── SP3 result card ──
        card = tk.Frame(self, bg="#16213e",
                        highlightthickness=1, highlightbackground="#334466")
        card.pack(padx=60, pady=20, fill="x")

        tk.Label(card, text="SP3 — Mentor Lookup Result",
                 bg="#16213e", fg="#00d4ff",
                 font=("Courier New", 10, "bold")).pack(anchor="w", padx=20, pady=(14, 8))

        self.result_frame = tk.Frame(card, bg="#16213e")
        self.result_frame.pack(fill="x", padx=20, pady=(0, 14))

        self.lbl_eid  = self._row(self.result_frame, "Mentor EID")
        self.lbl_name = self._row(self.result_frame, "Mentor Name")
        self.lbl_date = self._row(self.result_frame, "Hire Date")

        # ── Buttons ──
        btn_frame = tk.Frame(self, bg="#1a1a2e")
        btn_frame.pack()

        tk.Button(btn_frame, text="▶  Run SP3",
                  bg="#004488", fg="white",
                  font=("Courier New", 10, "bold"), relief="flat",
                  padx=16, pady=8, cursor="hand2",
                  command=self.run_sp3).pack(side="left", padx=8)

        tk.Button(btn_frame, text="← Logout",
                  bg="#333344", fg="#aaaaaa",
                  font=("Courier New", 9), relief="flat",
                  padx=12, pady=8, cursor="hand2",
                  command=self.logout).pack(side="left", padx=8)

        self.status = tk.Label(self, text="", bg="#1a1a2e",
                               fg="#ffaa00", font=("Courier New", 9))
        self.status.pack(pady=8)

    def _row(self, parent, label_text):
        row = tk.Frame(parent, bg="#16213e")
        row.pack(fill="x", pady=3)
        tk.Label(row, text=f"{label_text}:", width=16, anchor="w",
                 bg="#16213e", fg="#666688",
                 font=("Courier New", 9)).pack(side="left")
        val = tk.Label(row, text="—", anchor="w",
                       bg="#16213e", fg="#e0e0e0",
                       font=("Courier New", 10, "bold"))
        val.pack(side="left")
        return val

    def set_user(self, username):
        self.welcome.config(text=f"Logged in as:  {username}")

    def run_sp3(self):
        try:
            conn   = get_connection()
            cursor = conn.cursor()

            # SP3 is a stored procedure — call with EXEC
            # The .sql script logic is encapsulated inside sp3
            cursor.execute("EXEC sp3")
            row = cursor.fetchone()
            conn.close()

            if row:
                self.lbl_eid.config( text=str(row.MentorEID))
                self.lbl_name.config(text=str(row.MentorName))
                self.lbl_date.config(text=str(row.MentorHireDate))
                self.status.config(text="SP3 executed successfully.", fg="#00ff88")
            else:
                self.lbl_eid.config(text="n/a")
                self.lbl_name.config(text="n/a")
                self.lbl_date.config(text="n/a")
                self.status.config(text="SP3 returned no rows.", fg="#ffaa00")

        except Exception as e:
            self.status.config(text=f"SP3 Error: {e}", fg="#ff4444")

    def logout(self):
        self.controller.frames[LoginPage].username.delete(0, "end")
        self.controller.frames[LoginPage].password.delete(0, "end")
        self.controller.frames[LoginPage].status.config(text="")
        self.controller.show_frame(LoginPage)


# ─────────────────────────────────────────
#  RUN
# ─────────────────────────────────────────
if __name__ == "__main__":
    app = FactoryApp()
    app.mainloop()