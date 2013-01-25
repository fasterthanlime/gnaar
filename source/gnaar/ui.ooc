
// libs
use glew
import glew

use dye
import dye/[core, input, sprite, text, math, primitives]

import math
import structs/[ArrayList, Stack, List]

use deadlogger
import deadlogger/[Log, Logger]

use sdl2
import sdl2/[Core, Event]

// internal
import gnaar/[dialogs, events, utils]

PositionFlavor: enum {
    STATIC
    FIXED
    CENTER
}

SizeFlavor: enum {
    AUTO
    LENGTH /* e.g. 12px */
    PERCENTAGE /* e.g. 33% */

    toString: func -> String {
        match this {
            case This AUTO => "auto"
            case This LENGTH => "length"
            case This PERCENTAGE => "percentage"
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

    position := PositionFlavor STATIC
    width := SizeFlavor AUTO
    height := SizeFlavor AUTO
    display := DisplayFlavor INLINE

    givenPos := vec2(0, 0)
    givenSize := vec2(0, 0)

    // computed size, will be invalid if dirty
    size := vec2(0, 0)

    hovered := false
    visible := true

    // if true, need a repack before display
    dirty := false

    draw: func (dye: DyeContext) {
        // override stuff here
    }

    touch: func {
        dirty = true
    }

    setWidth: func ~length (value: Float) {
        givenSize x = value
        setWidthFlavor(SizeFlavor LENGTH)
        touch()
    }

    setRelativeWidth: func (value: Float) {
        givenSize x = value
        setWidthFlavor(SizeFlavor PERCENTAGE)
        touch()
    }

    setWidthFlavor: func (=width) {
        touch()
    }

    setHeight: func ~length (value: Float) {
        givenSize y = value
        setHeightFlavor(SizeFlavor LENGTH)
        touch()
    }

    setRelativeHeight: func (value: Float) {
        givenSize y = value
        setHeightFlavor(SizeFlavor PERCENTAGE)
        touch()
    }

    setHeightFlavor: func (=height) {
        touch()
    }

    setSize: func (x, y: Float) {
        setWidth(x)
        setHeight(y)
    }

    setDisplayFlavor: func (=display)

    setPositionFlavor: func (=position)

    process: func (e: GEvent) {
        // do what you want!
        //"Widget %s got event %s" printfln(class name, e getName())
    }

    collideTree: func (needle: Vec2, cb: Func (Widget, Bool)) {
        cb(this, contains?(needle))
    }

    contains?: func (needle: Vec2) -> Bool {
        BoundingBox contains?(pos, size, needle, false)
    }

}

Panel: class extends Widget {

    logger := Log getLogger(This name)
    children := ArrayList<Widget> new()

    margin := vec2(0, 0)
    padding := vec2(0, 0)

    backgroundColorRect: GlRectangle

    init: func {
        display = DisplayFlavor BLOCK
    }

    add: func (widget: Widget) {
        children add(widget)
        widget parent = this
        touch()
    }

    collideTree: func (needle: Vec2, cb: Func (Widget, Bool)) {
        super(needle, cb)

        subNeedle := needle sub(pos)
        for (child in children) {
            child collideTree(subNeedle, cb)
        }
    }

    draw: func (dye: DyeContext) {
        if (!visible) return

        if (dirty) {
            repack()
        }

        glPushMatrix()
        glTranslatef(pos x, pos y, 0)
        if (backgroundColorRect) {
            backgroundColorRect size set!(size)
            backgroundColorRect draw(dye)
        }

        for (c in children) {
            c draw(dye)
        }
        glPopMatrix()
    }

    setBackgroundColor: func (color: Color) {
        if (!backgroundColorRect) {
            backgroundColorRect = GlRectangle new()
            backgroundColorRect center = false
        }
        backgroundColorRect color set!(color)
    }

    resize: func {
        match width {
            case SizeFlavor LENGTH =>
                size x = givenSize x
            case SizeFlavor PERCENTAGE =>
                if (!parent) {
                    Exception new("Percentage-sized width with no parent") throw()
                }

                size x = parent size x * (givenSize x * 0.01)
            case =>
                //Exception new("Unsupported size flavor: %d" format(width)) throw()
        }

        match height {
            case SizeFlavor LENGTH =>
                size y = givenSize y
            case SizeFlavor PERCENTAGE =>
                if (!parent) {
                    Exception new("Percentage-sized height with no parent") throw()
                }

                size y = parent size y * (givenSize y * 0.01)
            case =>
                //Exception new("Unsupported size flavor: %d" format(height)) throw()
        }
    }

    repack: func {
        logger info("Resizing, width = %s, height = %s, givenSize = %s",
            width toString(), height toString(), givenSize _)
        resize()
        logger info("Resized to %s", size _)

        logger info("Repacking with %d children", children size)

        baseX := margin x
        baseY := size y - margin y

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

            if (child position == PositionFlavor CENTER) {
                halfChildSize := child size mul(0.5)

                logger info("centering, halfSize = %s, halfChildSize = %s",
                    size mul(0.5) _, halfChildSize _)

                newpos := size mul(0.5) sub(halfChildSize)
                logger info(" - center, (%.2f, %.2f)", newpos x, newpos y)
                child pos set!(newpos)
            } else {
                logger info(" - static, (%.2f, %.2f)", x, y)
                child pos set!(x, y)
            }

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

    color := Color new(220, 220, 220)

    init: func (value: String, fontSize := 20) {
        _text = GlText new(Frame fontPath, value, fontSize)
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
        _text pos set!(adjustedPos())
        _text render(dye)
    }

    contains?: func (needle: Vec2) -> Bool {
        BoundingBox contains?(adjustedPos(), size, needle, false)
    }

    adjustedPos: func -> Vec2 {
        pos add(margin) sub(0, size y)
    }

    repack: func {
        size set!(_text size add(margin))
    }

}

Frame: class extends Panel {

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger(This name)

    scene: Scene
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
    init: func (=scene) {
        super()

        input = scene input
        setSize(scene size x, scene size y)

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

        collideTree(mousePos, |widget, touching| {
            if (touching) {
                if (!widget hovered) {
                    widget hovered = true
                    widget process(MouseLeaveEvent new(mousePos))
                }
            } else {
                if (widget hovered) {
                    widget hovered = false
                    widget process(MouseEnterEvent new(mousePos))
                }
            }
        })
    }

    initEvents: func {
        input onMousePress(MouseButton LEFT, ||
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(MouseButton LEFT, ||
            dragStart = false
            if (dragging) {
                dragging = false
                queue push(DragStopEvent new())
            } else {
                clickPos := input getMousePos()
                clickEvent := ClickEvent new(MouseButton LEFT, clickPos)

                logger info("Click at %s", clickPos _)
                collideTree(clickPos, |widget, touching|
                    if (touching) {
                        widget process(clickEvent)
                    }
                )

                queue push(clickEvent)
            }
        )

        input onMouseRelease(MouseButton MIDDLE, ||
            queue push(ClickEvent new(MouseButton MIDDLE, input getMousePos()))
        )

        input onMouseRelease(MouseButton RIGHT, ||
            queue push(ClickEvent new(MouseButton RIGHT, input getMousePos()))
        )
    }

    draw: func (dye: DyeContext) {
        group draw(dye)

        // draw children
        super(dye)
    }

}
                
