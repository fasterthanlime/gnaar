
// third party
use yaml
import yaml/[Parser, Document]

use dye
import dye/[core, math]

// sdk
import io/File
import structs/[HashMap, List, ArrayList]

/* YAML utils */

parseYaml: func (path: String) -> DocumentNode {
    file := File new(path)
    if (!file exists?()) {
        return null
    }

    parser := YAMLParser new()
    parser setInputFile(path)

    doc := Document new()
    parser parseAll(doc)
    parser destroy()
    doc getRootNode()
}

extend DocumentNode {

    toMap: func -> HashMap<String, DocumentNode> {
        match this {
            case mn: MappingNode =>
                mn toHashMap()
            case =>
                Exception new("Called toMap() on a %s" format(class name)) throw()
                null
        }
    }

    toList: func -> List<DocumentNode> {
        match this {
            case sn: SequenceNode =>
                sn toList()
            case =>
                Exception new("Called toList() on a %s" format(class name)) throw()
                null
        }
    }

    toScalar: func -> String {
        match this {
            case sn: ScalarNode =>
                sn value
            case =>
                Exception new("Called toScalar() on a %s" format(class name)) throw()
                null
        }
    }

    toInt: func -> Int {
        toScalar() toInt()
    }

    toFloat: func -> Float {
        toScalar() toFloat()
    }

    toBool: func -> Bool {
        toScalar() trim() == "true"
    }

    toVec2: func -> Vec2 {
        list := toList()
        vec2(list[0] toFloat(), list[1] toFloat())
    }

    toVec2List: func -> List<Vec2> {
        list := toList()
        result := ArrayList<Vec2> new()
        list map(|e| e toVec2())
        result
    }

}

extend String {

    toScalar: func -> ScalarNode {
        ScalarNode new(this)
    }

}

extend Int {

    toScalar: func -> ScalarNode {
        ScalarNode new(this toString())
    }

}

extend Bool {

    toScalar: func -> ScalarNode {
        (this ? "true" : "false") toScalar()
    }

}

extend Vec2 {

    toSeq: func -> SequenceNode {
        seq := SequenceNode new()
        seq add(ScalarNode new(x toString()))
        seq add(ScalarNode new(y toString()))
        seq
    }

}

/* List .yml files in a directory, with the '.yml' extension stripped */

listDefs: func (path: String) -> List<String> {
        File new(path) \
            getChildrenNames() \
            filter(|x| x endsWith?(".yml")) \
            map(|x| x[0..-5]) \
}

