
// third-party stuff
import dye/[math, input]

// sdk stuff
import structs/ArrayList

EventListener: abstract class {

    onEvent: func (event: GEvent)

}

EventQueue: class {

    subscribers := ArrayList<EventListener> new()
    events := ArrayList<GEvent> new()

    push: func (e: GEvent) {
        events add(e)
    }

    subscribe: func (listener: EventListener) {
        subscribers add(listener)
    }

    dispatch: func {
        while (!events empty?()) {
            e := events removeAt(0)
            for (sub in subscribers) {
                sub onEvent(e)
            }
        }
    }

}
                

/* Event types */

GEvent: abstract class {

    getName: abstract func -> String

}

MouseEnterEvent: class extends GEvent {

    pos: Vec2

    init: func (=pos)

    getName: func -> String {
        "mouseenter"
    }
    
}

MouseLeaveEvent: class extends GEvent {

    pos: Vec2

    init: func (=pos)

    getName: func -> String {
        "mouseleave"
    }
    
}

ClickEvent: class extends GEvent {

    button: Int
    pos: Vec2

    init: func (=button, =pos)

    getName: func -> String {
        "click"
    }

}

DragStartEvent: class extends GEvent {

    pos: Vec2

    init: func (=pos)

    getName: func -> String {
        "dragstart"
    }

}

DragStopEvent: class extends GEvent {

    getName: func -> String {
        "dragstop"
    }

}

DragEvent: class extends GEvent {

    delta: Vec2

    init: func (=delta)

    getName: func -> String {
        "drag"
    }

}

