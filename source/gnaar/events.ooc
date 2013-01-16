
// third-party stuff
import dye/[math, input]

// sdk stuff
import structs/ArrayList

GEvent: class {

}

ClickEvent: class extends GEvent {

    button: Int
    pos: Vec2

    init: func (=button, =pos)

}

DragStartEvent: class extends GEvent {

    pos: Vec2

    init: func (=pos)

}

DragStopEvent: class extends GEvent {

}

DragEvent: class extends GEvent {

    delta: Vec2

    init: func (=delta)

}

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
                
