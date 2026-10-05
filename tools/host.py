"""TI API adapter for the same Lua bundle; not a TI OS emulator."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT / ".devdeps"))
from lupa.lua51 import LuaRuntime, lua_type
from PIL import Image, ImageDraw, ImageFont
from build import bundle


class Graphics:
    def __init__(self,width,height):
        self.width,self.height=width,height
        self.color=(221,234,233)
        self.fonts={}
        self.setFont(None,"sansserif","r",10)
        self.begin()

    def begin(self):
        self.image=Image.new("RGB",(self.width,self.height),(15,23,36))
        self.draw=ImageDraw.Draw(self.image)
        self.texts=[]

    def setColorRGB(self,_gc,r,g,b):
        self.color=(int(r),int(g),int(b))

    def setFont(self,_gc,family,style,size):
        if family not in ("sansserif","serif") or size not in (7,9,10,11,12,24):
            raise ValueError("Font is outside the Gen1 TI-Nspire supported set")
        pixels=max(8,int(size*1.3))
        if pixels not in self.fonts:
            candidates=("C:/Windows/Fonts/segoeui.ttf",
                        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
            path=next((p for p in candidates if Path(p).is_file()),None)
            self.fonts[pixels]=(ImageFont.truetype(path,pixels) if path
                                else ImageFont.load_default(size=pixels))
        self.font=self.fonts[pixels]

    def fillRect(self,_gc,x,y,w,h):
        if w<=0 or h<=0:
            return
        self.draw.rectangle((int(x),int(y),int(x+w-1),int(y+h-1)),fill=self.color)

    def drawRect(self,_gc,x,y,w,h):
        self.draw.rectangle((int(x),int(y),int(x+w),int(y+h)),outline=self.color)

    def drawString(self,_gc,text,x,y,alignment="top"):
        self.draw.text((int(x),int(y)),text,font=self.font,fill=self.color,anchor="lt")
        self.texts.append((text,int(x),int(y),self.font.getbbox(text)))

    def getStringWidth(self,_gc,text):
        return self.font.getlength(text)

    def table(self,lua):
        methods=("setColorRGB","setFont","fillRect","drawRect","drawString","getStringWidth")
        return lua.table_from({name:getattr(self,name) for name in methods})


def plain(value,depth=0):
    if depth>8:
        raise ValueError("Save nesting is too deep")
    if lua_type(value)=="table":
        return {str(key):plain(child,depth+1) for key,child in value.items()}
    if value is None or isinstance(value,(str,int,float,bool)):
        return value
    raise ValueError("Unsupported save value")


def reject_constant(value):
    raise ValueError(f"Nonfinite JSON value: {value}")


class Application:
    def __init__(self,width=320,height=240):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.gc=Graphics(width,height)
        self.graphics=self.gc.table(self.lua)
        self.dirty=True
        self.running=False
        window=self.lua.table_from({"width":lambda _:width,"height":lambda _:height,
                                    "invalidate":self.invalidate})
        self.lua.globals().platform=self.lua.table_from({"window":window})
        self.lua.globals().timer=self.lua.table_from({"start":self.start,"stop":self.stop})
        self.lua.globals().on=self.lua.table()
        self.lua.execute(bundle())
        self.on=self.lua.globals().on
        self.on.construction()
        self.on.resize(width,height)
        self.on.activate()

    def invalidate(self,*args):
        self.dirty=True

    def start(self,seconds):
        if seconds!=0.1:
            raise ValueError("Unexpected timer interval")
        self.running=True

    def stop(self):
        self.running=False

    def key(self,key):
        if key in ("up","down","left","right"):
            self.on.arrowKey(key)
        elif key=="enter":
            self.on.enterKey()
        elif key=="escape":
            self.on.escapeKey()
        else:
            self.on.charIn(key)

    def tick(self):
        if self.running:
            self.on.timer()

    def paint(self):
        self.gc.begin()
        self.on.paint(self.graphics)
        self.dirty=False
        return self.gc.image

    def snapshot(self):
        return plain(self.on.save())

    def save(self,path):
        content=json.dumps(self.snapshot(),ensure_ascii=True,allow_nan=False,indent=2)
        temporary=path.with_name(path.name+".tmp")
        temporary.write_text(content,encoding="utf-8")
        temporary.replace(path)

    def load(self,path):
        if not path.exists():
            return False
        try:
            if path.stat().st_size>32768:
                raise ValueError("Save file exceeds 32 KiB")
            data=json.loads(path.read_text("utf-8"),parse_constant=reject_constant)
            if not isinstance(data,dict):
                raise ValueError("Save must be a JSON object")
            self.on.restore(self.lua.table_from(data,recursive=True))
        except (OSError,ValueError,OverflowError,RecursionError):
            self.on.restore("Unreadable simulator save")
            self.invalidate()
            return False
        self.invalidate()
        return True
