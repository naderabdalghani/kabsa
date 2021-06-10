import os
import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox

PADDING = 5


class GUI(tk.Tk):
    def __init__(self):
        tk.Tk.__init__(self)
        self.title('kabsa Compiler')
        self.iconbitmap("./assets/icon.ico")

        self.input_filename = tk.StringVar()
        self.output_filepath = tk.StringVar()

        for row, (label, var, cmd) in enumerate((('Input File:', self.input_filename, self.get_input_filename),
                                                 ('Output Directory:', self.output_filepath, self.get_output_filepath))
                                                ):
            tk.Label(self, text=label).grid(row=row, column=0, sticky=tk.W, padx=PADDING, pady=PADDING)
            tk.Entry(self, textvariable=var).grid(row=row, column=1, sticky=tk.W + tk.E, padx=PADDING, pady=PADDING)
            tk.Button(self, text='Browse', command=cmd).grid(row=row, column=2, padx=PADDING, pady=PADDING)

        tk.Button(self, text='Compile', command=self.compile).grid(row=2, column=2, rowspan=2, sticky=tk.W,
                                                                   padx=PADDING, pady=PADDING)

        self.columnconfigure(1, weight=1)
        self.rowconfigure(4, weight=1)

    def get_input_filename(self):
        self.input_filename.set(filedialog.askopenfilename())

    def get_output_filepath(self):
        self.output_filepath.set(filedialog.askdirectory())

    def compile(self):
        if not self.input_filename.get():
            messagebox.showerror('Error', 'No input filename specified.')
            return
        if not self.output_filepath.get():
            messagebox.showerror('Error', 'No output filepath specified.')
            return
        if not os.path.isfile(self.input_filename.get()):
            messagebox.showerror('Error', 'Invalid input filename specified.')
            return
        if not os.path.isdir(self.output_filepath.get()):
            messagebox.showerror('Error', 'Invalid output file directory specified.')
            return
        if not os.path.exists("compiler.exe"):
            messagebox.showerror('Error', 'compiler.exe file is not exists in the same directory of \"gui.py\"')
            return
        commands = ".\compiler.exe" + " \"\'" + str(self.input_filename.get()) + "\'\"" + " \"\'" + str(self.output_filepath.get()) + "\'\""
        subprocess.call('%SYSTEMROOT%\System32\WindowsPowerShell/v1.0/powershell.exe -Command ' + str(commands), shell=True)
        # messagebox.showinfo("Success","Assembly file created successfully at:" + str(" \"" + str(self.output_filepath.get()) + "\"") + ", with name: " + 
        # str( os.path.basename(self.input_filename.get()).split('.')[0] + ".asm"))


def main():
    GUI().mainloop()


if __name__ == '__main__':
    main()
