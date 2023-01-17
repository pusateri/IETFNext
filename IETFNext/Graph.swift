//
//  Graph.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/16/23.
//

import Foundation
import GraphViz


enum RFCGraphMode: String {
    case start
    case updates
    case updatedBy
    case obsoletes
    case obsoletedBy
}

private func makeNode(rfc: RFC, nodes: inout [String:Node], mode: RFCGraphMode) -> Node {
    if let node = nodes[rfc.name!] {
        return node
    }

    var node = Node(rfc.name!)
    nodes[rfc.name!] = node

    /*
    node.fontName = "Monospace"
    node.strokeWidth = 2.0
    node.strokeColor = .rgb(red: 55, green: 44, blue: 33)
    if mode == .obsoletes {
        node.style = .dashed
    } else if mode == .start {
        node.shape = .doublecircle
    }
     */
    node.href = "https://www.rfc-editor.org/rfc/\(rfc.name!.lowercased()).html"
    return node
}

private func makeEdge(from: Node, to: Node, mode: RFCGraphMode) -> GraphViz.Edge {
    var edge: GraphViz.Edge
    switch(mode) {
    case .updates, .obsoletes, .start:
        edge = Edge(from: from, to: to)
    case .updatedBy, .obsoletedBy:
        edge = Edge(from: to, to: from)
    }
    if mode == .obsoletes || mode == .obsoletedBy {
        edge.exteriorLabel = "Obsoletes"
        //edge.fontName = "Monospace"
    } else {
        edge.exteriorLabel = "Updates"
    }
    edge.fontSize = 10.0
    return edge
}

func buildGraph(start: RFC) -> Graph {
    var seen = Set<RFC>()
    var todo = Set<RFC>()
    var nodes: [String:Node] = [:]
    var graph = Graph(directed: true)
    graph.center = true
    todo.insert(start)
    seen.insert(start)

    while !todo.isEmpty {
        let current = todo.removeFirst()
        let current_node = makeNode(rfc: current, nodes: &nodes, mode: .start)

        if var upBy: Set<RFC> = current.updatedBy as? Set<RFC> {
            upBy.subtract(seen)
            if !upBy.isEmpty {
                todo = todo.union(upBy)
                var list: [RFC] = Array(upBy)
                while !list.isEmpty {
                    if let next = list.popLast() {
                        seen.insert(next)
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .updatedBy)
                        let edge = makeEdge(from: current_node, to: node, mode: .updatedBy)
                        graph.append(edge)
                    }
                }
            }
        }
        if var updates: Set<RFC> = current.updates as? Set<RFC> {
            updates.subtract(seen)
            if !updates.isEmpty {
                todo = todo.union(updates)
                var list: [RFC] = Array(updates)
                while !list.isEmpty {
                    if let next = list.popLast() {
                        seen.insert(next)
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .updates)
                        let edge = makeEdge(from: current_node, to: node, mode: .updates)
                        graph.append(edge)
                    }
                }
            }
        }
        if var obsoletes: Set<RFC> = current.obsoletes as? Set<RFC> {
            obsoletes.subtract(seen)
            if !obsoletes.isEmpty {
                todo = todo.union(obsoletes)
                var list: [RFC] = Array(obsoletes)
                while !list.isEmpty {
                    if let next = list.popLast() {
                        seen.insert(next)
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .obsoletes)
                        let edge = makeEdge(from: current_node, to: node, mode: .obsoletes)
                        graph.append(edge)
                    }
                }
            }
        }
        if var obsBy: Set<RFC> = current.obsoletedBy as? Set<RFC> {
            obsBy.subtract(seen)
            if !obsBy.isEmpty {
                todo = todo.union(obsBy)
                var list: [RFC] = Array(obsBy)
                while !list.isEmpty {
                    if let next = list.popLast() {
                        seen.insert(next)
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .obsoletedBy)
                        let edge = makeEdge(from: current_node, to: node, mode: .obsoletedBy)
                        graph.append(edge)
                    }
                }
            }
        }
    }
    return graph
}
