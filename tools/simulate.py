"""Play Bitling in a desktop window, using the unchanged TI Lua bundle."""
from pathlib import Path
import argparse
import sys
import tkinter as tk
from tkinter import messagebox

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT / ".devdeps"))
from PIL import Image,ImageTk
from host import Application


class Simulator:
    def __init__(self,app,save_path,scale):
        self.app,self.save_path,self.scale=app,save_path,scale
        self.root=tk.Tk()
        self.root.title("Bitling-Nspire | Lua host simulator")
        self.root.configure(bg="#0f1724")
        self.label=tk.Label(self.root,bd=0)
        self.label.pack(padx=12,pady=12)
        tk.Label(self.root,text="Arrows / Enter / Esc / M   •   Ctrl+S saves   •   F12 screenshot",
                 fg="#849ca6",bg="#0f1724").pack(pady=(0,12))
        self.root.bind("<Key>",self.key)
        self.root.bind("<FocusOut>",self.focus_out)
        self.root.bind("<FocusIn>",self.focus_in)
        self.root.protocol("WM_DELETE_WINDOW",self.close)
        self.redraw()
        self.root.after(100,self.tick)

    def redraw(self):
        image=self.app.paint()
        image=image.resize((image.width*self.scale,image.height*self.scale),
                           Image.Resampling.NEAREST)
        self.photo=ImageTk.PhotoImage(image)
        self.label.configure(image=self.photo)

    def key(self,event):
        if event.state & 4 and event.keysym.lower()=="s":
            try:
                self.app.save(self.save_path)
                self.root.title("Bitling-Nspire | memory saved")
            except (OSError,ValueError) as error:
                messagebox.showerror("Save failed",str(error))
            return "break"
        if event.keysym=="F12":
            out=ROOT/"build"
            out.mkdir(exist_ok=True)
            self.app.paint().save(out/"simulator.png")
            self.root.title("Bitling-Nspire | screenshot: build/simulator.png")
            return "break"
        mapping={"Up":"up","Down":"down","Left":"left","Right":"right",
                 "Return":"enter","KP_Enter":"enter","Escape":"escape"}
        self.app.key(mapping.get(event.keysym,event.char.lower()))
        self.redraw()

    def tick(self):
        self.app.tick()
        if self.app.dirty:
            self.redraw()
        self.root.after(100,self.tick)

    def focus_out(self,event):
        if event.widget==self.root:
            self.app.on.deactivate()

    def focus_in(self,event):
        if event.widget==self.root:
            self.app.on.activate()

    def close(self):
        choice=messagebox.askyesnocancel("Close Bitling","Save your game before closing?")
        if choice is None:
            return
        if choice:
            try:
                self.app.save(self.save_path)
            except (OSError,ValueError) as error:
                messagebox.showerror("Save failed",str(error))
                return
        self.root.destroy()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size",choices=("320x240","318x212"),default="318x212")
    parser.add_argument("--scale",type=int,choices=(1,2,3,4),default=3)
    parser.add_argument("--save",type=Path,default=ROOT/"simulator-save.json")
    parser.add_argument("--snapshot",type=Path)
    args=parser.parse_args()
    width,height=map(int,args.size.split("x"))
    app=Application(width,height)
    app.load(args.save)
    if args.snapshot:
        args.snapshot.parent.mkdir(parents=True,exist_ok=True)
        app.paint().save(args.snapshot)
        return
    Simulator(app,args.save,args.scale).root.mainloop()


if __name__=="__main__":
    main()
