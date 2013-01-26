
// our stuff
import gnaar/[utils, ui]

// third-party stuff
use dye
import dye/[core]

use yaml
import yaml/[Parser, Document]

UILoader: class {

    root: Frame

    init: func (factory: UIFactory) {

    }

    parse: func (path: String, frame: Frame) {
        doc := parseYaml(path)

        doc toMap each(|k, v|
            widget := parseWidget(k, v toMap())
            if (widget) {
                frame add(widget)
            }
        )
    }

    parseWidget: func (def: String, map: HashMap<String, DocumentNode>) -> Widget {
        l := def indexOf?("(")
        r := def indexOf?(")")
        if (l == -1 || r == -1 || l > r) {
            logger error("Invalid widget definition: %s"
            return null
        }

        id := def[0..l]
        type := def[l..r]
        "Got widget: %s(%s)" printfln(id, type)

        props := HashMap<String, DocumentNode> new()
        children := ArrayList<Widget> new()

        map each(|k, v|
            if (k contains?("(")) {
                children add(parseWidget(k, v toMap()))
            } else {
                props put(k, v)
            }
        )

        widget := factory spawn(type, props)
    }

}

UIFactory: class {
    
    spawn: func (type: String, props: HashMap<String, DocumentNode>) -> Widget {
        widget := match type {
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
        }

        widget absorb(factory, props)
        widget
    }

}

UILoaderException: class extends Exception {

    init: super func

}

