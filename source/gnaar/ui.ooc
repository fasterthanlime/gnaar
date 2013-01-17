
// libs
use dye
import dye/[core, input, sprite, font, math, primitives]

import math
import structs/[ArrayList, Stack, List]

use deadlogger
import deadlogger/[Log, Logger]

use sdl2
import sdl2/[Core, Event]

// internal
import gnaar/[dialogs, events]

FloatFlavor: enum {
    NONE
    LEFT
    RIGHT
    INHERIT
}

PositionFlavor: enum {
    STATIC
    ABSOLUTE
    FIXED
    RELATIVE
    INHERIT
}

SizeFlavor: enum {
    AUTO
    LENGTH /* e.g. 12px */
    PERCENTAGE /* e.g. 33% */
    INHERIT

    toString: func -> String {
        match this {
            case This AUTO => "auto"
            case This LENGTH => "length"
            case This PERCENTAGE => "percentage"
            case This INHERIT => "inherit"
        }
    }
}

DisplayFlavor: enum {
    INLINE
    BLOCK
    INLINEBLOCK
}

Widget: class extends GlDrawable {

    // can be null
    parent: Panel

    floating := FloatFlavor NONE
    position := PositionFlavor STATIC
    width := SizeFlavor AUTO
    height := SizeFlavor AUTO
    display := DisplayFlavor INLINE

    givenPos := vec2(0, 0)
    givenSize := vec2(0, 0)

    // computed size, will be invalid if dirty
    size := vec2(0, 0)

    visible := true

    // if true, need a repack before display
    dirty := false

    draw: func (dye: DyeContext) {
        // override stuff here
    }

    setWidth: func ~length (value: Float) {
        givenSize x = value
        setWidthFlavor(SizeFlavor LENGTH)
    }

    setRelativeWidth: func (value: Float) {
        givenSize x = value
        setWidthFlavor(SizeFlavor PERCENTAGE)
    }

    setWidthFlavor: func (=width)

    setHeight: func ~length (value: Float) {
        givenSize y = value
        setHeightFlavor(SizeFlavor LENGTH)
    }

    setRelativeHeight: func (value: Float) {
        givenSize y = value
        setHeightFlavor(SizeFlavor PERCENTAGE)
    }

    setHeightFlavor: func (=height)

    setSize: func (x, y: Float) {
        setWidth(x)
        setHeight(y)
    }

    setDisplay: func (=display)

}

Panel: class extends Widget {

    logger := Log getLogger(This name)
    children := ArrayList<Widget> new()

    margin := vec2(0, 0)
    padding := vec2(0, 0)

    init: func {
        display = DisplayFlavor BLOCK
    }

    add: func (widget: Widget) {
        children add(widget)
        widget parent = this
        touch()
    }

    touch: func {
        dirty = true
    }

    draw: func (dye: DyeContext) {
        if (!visible) return

        if (dirty) {
            repack()
        }

        for (c in children) {
            c draw(dye)
        }
    }

    repack: func {
        logger info("Repacking with %d children", children size)

        baseX := margin x
        baseY := margin y

        if (height == SizeFlavor LENGTH) {
            baseY = givenSize y - margin y
        }

        (x, y) := (baseX, baseY)

        previousChild : Widget = null
        currentDisplay := DisplayFlavor INLINE

        newlined := true

        for (child in children) {
            if (child display == DisplayFlavor BLOCK && !newlined) {
                x = baseX
                newlined = true

                if (previousChild) {
                    y -= (previousChild size y + padding y)
                }
            }

            logger info(" - (%.2f, %.2f)", x, y)
            child pos set!(x, y)

            if (child display == DisplayFlavor BLOCK) {
                newlined = true
                x = baseX
                y -= (child size y + padding y)
            } else {
                newlined = false
                x += (child size x + padding x)
            }

            previousChild = child
        }

        dirty = false

        if (parent) {
            parent repack()
        }
    }

}

Label: class extends Widget {

    margin := vec2(0, 0)
    _text: GlText

    color := Color black()

    init: func (value: String) {
        _text = GlText new(Frame fontPath, value)
        _text pos set!(0, 0)
        repack()
    }

    setValue: func (value: String) {
        _text value = value
        repack()
        if (parent) {
            parent touch()
        }
    }

    setValue: func ~var (value: String, args: ...) {
        setValue(value format(args))
    }

    draw: func (dye: DyeContext) {
        _text pos set!(pos add(margin) sub(0, size y))
        _text draw(dye)
    }

    repack: func {
        size set!(_text size add(margin))
    }

}

Frame: class extends Panel {

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger(This name)

    dye: DyeContext
    input: Input

    queue := EventQueue new()

    // mouse stuff
    prevMousePos := vec2(0, 0)
    delta := vec2(0, 0)

    // drag stuff
    dragging := false
    dragStart := false
    dragThreshold := 2.0
    dragPath := vec2(0, 0)
    
    // Dye groups
    group: GlGroup { get set }
    hudGroup: GlGroup
    dialogGroup: GlGroup
    
    // Dialogs
    dialogStack := Stack<Dialog> new()

    // Constructor
    init: func (=dye) {
        super()

        input = dye input
        setSize(dye width, dye height)

        group = GlGroup new()

        hudGroup = GlGroup new()
        group add(hudGroup)

        dialogGroup = GlGroup new()
        group add(dialogGroup)

        initEvents()
        prevMousePos set!(input getMousePos())
    }

    push: func (dialog: Dialog) {
        dialogStack push(dialog)
    }

    pop: func (dialog: Dialog) {
        if (root?) return
        dialogStack pop()
    }

    root?: Bool { get { dialogStack empty?() } }

    update: func {
        updateMouse()

        if (!root?) {
            dialog := dialogStack peek()
            dialog update()
        }

        queue dispatch()
    }

    updateMouse: func {
        mousePos := input getMousePos()
        delta = mousePos sub(prevMousePos)

        if (dragging) {
            queue push(DragEvent new(delta))
        }

        if (dragStart) {
            dragPath add!(delta)

            if (dragPath norm() >= dragThreshold) {
                // Yup, it's a drag
                dragStart = false
                dragging = true

                queue push(DragStartEvent new(mousePos sub(dragPath)))
                queue push(DragEvent new(dragPath))
            }
        }

        prevMousePos set!(mousePos)
    }

    initEvents: func {
        input onMousePress(Buttons LEFT, ||
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(Buttons LEFT, ||
            dragStart = false
            if (dragging) {
                dragging = false
                queue push(DragStopEvent new())
            } else {
                queue push(ClickEvent new(Buttons LEFT, input getMousePos()))
            }
        )

        input onMouseRelease(Buttons MIDDLE, ||
            queue push(ClickEvent new(Buttons MIDDLE, input getMousePos()))
        )

        input onMouseRelease(Buttons RIGHT, ||
            queue push(ClickEvent new(Buttons RIGHT, input getMousePos()))
        )
    }

    draw: func (dye: DyeContext) {
        group draw(dye)
        super(dye)
    }

}
                
