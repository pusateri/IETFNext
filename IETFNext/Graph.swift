//
//  Graph.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/16/23.
//

import SwiftUI
import GraphViz


enum RFCGraphMode: String {
    case start
    case updates
    case updatedBy
    case obsoletes
    case obsoletedBy
}

private func makeNode(rfc: RFC, nodes: inout [String:Node], mode: RFCGraphMode, colorScheme: ColorScheme) -> Node {
    if let node = nodes[rfc.name2] {
        return node
    }

    var node = Node(rfc.name2)
    nodes[rfc.name2] = node

    if mode == .start {
        node.shape = .doublecircle
    }
    if let obsBy: Set<RFC> = rfc.obsoletedBy as? Set<RFC>, obsBy.count > 0 {
        node.style = .dashed
    }
    if colorScheme == .dark {
        node.strokeColor = .named(.white)
    }
    node.textColor = .rgb(red:0x3A, green:0x82, blue: 0xF6)
    node.href = "https://www.rfc-editor.org/rfc/\(rfc.name!.lowercased()).html"
    return node
}

private func makeEdge(from: Node, to: Node, mode: RFCGraphMode, colorScheme: ColorScheme) -> GraphViz.Edge {
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
    if colorScheme == .dark {
        edge.textColor = .named(.white)
        edge.strokeColor = .named(.white)
    }
    return edge
}

func buildGraph(start: RFC, colorScheme: ColorScheme) -> Graph {
    var seen = Set<RFC>()
    var todo = Set<RFC>()
    var nodes: [String:Node] = [:]
    var graph = Graph(directed: true)
    graph.fontNamingConvention = Graph.FontNamingConvention.svg
    graph.fontName = "Monospace"
    if colorScheme == .dark {
        graph.backgroundColor = .named(.black)
        graph.textColor = .named(.white)
    }
    todo.insert(start)
    seen.insert(start)

    while !todo.isEmpty {
        let current = todo.removeFirst()
        let current_node = makeNode(rfc: current, nodes: &nodes, mode: .start, colorScheme: colorScheme)
        graph.append(current_node)

        if var upBy: Set<RFC> = current.updatedBy as? Set<RFC> {
            upBy.subtract(seen)
            if !upBy.isEmpty {
                todo = todo.union(upBy)
                var list: [RFC] = Array(upBy)
                while !list.isEmpty {
                    if let next = list.popLast() {
                        seen.insert(next)
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .updatedBy, colorScheme: colorScheme)
                        graph.append(node)
                        let edge = makeEdge(from: current_node, to: node, mode: .updatedBy, colorScheme: colorScheme)
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
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .updates, colorScheme: colorScheme)
                        graph.append(node)
                        let edge = makeEdge(from: current_node, to: node, mode: .updates, colorScheme: colorScheme)
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
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .obsoletes, colorScheme: colorScheme)
                        graph.append(node)
                        let edge = makeEdge(from: current_node, to: node, mode: .obsoletes, colorScheme: colorScheme)
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
                        let node = makeNode(rfc: next, nodes: &nodes, mode: .obsoletedBy, colorScheme: colorScheme)
                        graph.append(node)
                        let edge = makeEdge(from: current_node, to: node, mode: .obsoletedBy, colorScheme: colorScheme)
                        graph.append(edge)
                    }
                }
            }
        }
    }
    return graph
}
