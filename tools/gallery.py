"""Render real callback-driven host views; these are not calculator photographs."""
from pathlib import Path
from host import Application,ROOT


def scene(mode,width=318,height=212):
    app=Application(width,height)
    if mode=="WORLD" or mode=="MENU" or mode=="DIALOGUE":
        app.key("enter")
        if mode!="DIALOGUE":
            app.key("escape")
        if mode=="MENU":
            app.key("m")
    elif mode=="BATTLE":
        raw=app.snapshot()
        raw["map"],raw["x"],raw["y"]="matrix",12,5
        raw["flags"]={name:True for name in ("started","forest","valley","matrix")}
        app.on.restore(app.lua.table_from(raw,recursive=True))
        app.key("enter")
        app.key("enter")
    elif mode!="HOME":
        index={"PET":1,"INVENTORY":2,"STATUS":3,"SAVE":4}[mode]
        for _ in range(index):
            app.key("down")
        app.key("enter")
    return app


def main():
    out=ROOT/"docs/screenshots"
    out.mkdir(parents=True,exist_ok=True)
    for mode in ("HOME","WORLD","BATTLE","PET","MENU","INVENTORY","STATUS","SAVE","DIALOGUE"):
        scene(mode).paint().save(out/(mode.lower()+".png"))
    print("Rendered host screenshots to docs/screenshots/")


if __name__=="__main__":
    main()
