
// third-party stuff
use dye
import dye/[core]

use yaml
import yaml/[Parser, Document]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import structs/[ArrayList, HashMap]

// our stuff
import gnaar/[utils, ui]

UILoader: class {

    root: Frame

    logger := Log getLogger(This name)
    factory: UIFactory

    init: func (=factory) {

    }

    load: func (frame: Frame, path: String) {
        doc := parseYaml(path)

        doc toMap() each(|k, v|
            widget := parseWidget(k, v toMap())
            if (widget) {
                frame add(widget)
            }
        )
    }

    parseWidget: func (def: String, map: HashMap<String, DocumentNode>) -> Widget {
        l := def indexOf('(')
        r := def indexOf(')')
        if (l == -1 || r == -1 || l > r) {
            logger error("Invalid widget definition: %s" format(def))
            return null
        }

        id := def[0..l]
        type := def[(l + 1)..r]
        logger info("Got widget: %s(%s)", id, type)

        props := HashMap<String, DocumentNode> new()
        children := ArrayList<Widget> new()

        map each(|k, v|
            if (k contains?("(")) {
                child := parseWidget(k, v toMap())
                if (child) {
                    children add(child)
                }
            } else {
                props put(k, v)
            }
        )

        widget := factory spawn(type, props)
        widget id = id

        match widget {
            case panel: Panel =>
                for (child in children) {
                    panel add(child)
                }
            case =>
                if (!children empty?()) {
                    logger error("Non-container widget has children: %s", widget class name)
                }
        }

        widget
    }

}

UIFactory: class {
    
    spawn: func (type: String, props: HashMap<String, DocumentNode>) -> Widget {
        widget: Widget = match type {
            case "panel" =>
                Panel new()
            case "label" =>
                Label new()
            case "button" =>
                Button new()
            case "icon" =>
                Icon new()
            case =>
                UILoaderException new("Unknown widget type: %s" format(type)) throw()
                null
        }

        if (widget) {
            widget absorb(props)
        }

        widget
    }

}

UILoaderException: class extends Exception {

    init: super func

}
