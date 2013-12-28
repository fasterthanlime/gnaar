
use dye
import dye/[core, input, sprite, text, primitives, math]

import gnaar/[ui, utils]

Dialog: class {

    frame: Frame
    input: Input
    group: GlGroup
    color := Color new(15, 15, 15)

    init: func (=frame) {
        group = GlGroup new()
        input = frame input sub()
        frame dialogGroup add(group)
    }

    update: func {
    }

    destroy: func {
        frame dialogGroup remove(group)
        input nuke()
        frame pop(this)
    }

}

InputDialog: class extends Dialog {
    
    prompt: String
    text, promptText: GlText

    cb: Func (String)

    initialized := false

    init: func (=frame, =prompt, =cb) {
        super(frame)

        bgRect := GlRectangle new()
        bgRect size set!(600, 120)
        bgRect color = color
        group add(bgRect)

        rect := GlRectangle new()
        rect size set!(600, 120)
        rect filled = false
        rect color = color lighten(0.1)
        group add(rect)

        promptText = GlText new(Frame fontPath, "> " + prompt)
        promptText color = color lighten(0.1)
        promptText pos set!(- rect size x / 2 + 10, 30)
        group add(promptText)

        text = GlText new(Frame fontPath, "")
        text color = color lighten(0.03)
        text pos set!(- rect size x / 2 + 10, -20)
        group add(text)

        group center!(frame scene dye mainPass)
    }

    update: func {
        if (initialized) return

        cb := this cb // silly workaround..
        input onKeyPress(|kev|
            match (kev scancode) {
                case KeyCode ESC =>
                    destroy()
                case KeyCode ENTER =>
                    destroy()
                    cb(text value)
                case KeyCode BACKSPACE =>
                    if (text value size > 0) {
                        text value = text value[0..-2]
                    }
                case =>
                    if (isPrintable(kev keycode)) {
                        text value = "%s%c" format(text value, kev keycode as Char)
                    }
            }
        )
        initialized = true
    }

}

AlertDialog: class extends Dialog {
    
    text: GlText

    cb: Func

    initialized := false

    init: func ~nocb (.frame, message: String) {
        init(frame, message, || noop := true)
    }

    init: func (=frame, message: String, =cb) {
        super(frame)

        bgRect := GlRectangle new()
        bgRect size set!(600, 80)
        bgRect color = color
        group add(bgRect)

        rect := GlRectangle new()
        rect size set!(600, 80)
        rect filled = false
        rect color = color lighten(0.1)
        group add(rect)

        text = GlText new(Frame fontPath, message)
        text color = color lighten(0.03)
        text pos set!(- rect size x / 2 + 10, 0)
        group add(text)

        group center!(frame scene dye mainPass)
    }

    update: func {
        if (initialized) return

        cb := this cb // silly workaround..
        input onKeyPress(|kev|
            destroy()
            cb()
        )

        input onMouseRelease(MouseButton LEFT, |ev|
            destroy()
            cb()
        )
        initialized = true
    }

}
