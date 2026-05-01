// lib/screens/list_screen.dart
// Pantalla de prototipo original – conservada como referencia.
// La pantalla activa del módulo de Marly es: assembly_screen.dart

import 'package:flutter/material.dart';
import '../models/data_structures/custom_list.dart';
import '../models/data_structures/custom_stack.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  CustomLinkedList<String> myNodes = CustomLinkedList<String>();
  CustomStack<String> myStack = CustomStack<String>();
  final TextEditingController _controller = TextEditingController();

  void _addData() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        myNodes.insert(_controller.text);
        myStack.push(_controller.text);
        _controller.clear();
      });
    }
  }

  void _undoData() {
    setState(() {
      final lastItem = myStack.pop();
      if (lastItem != null) {
        myNodes.delete(lastItem);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ensamble de PC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer última pieza',
            onPressed: myStack.isEmpty ? null : _undoData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Agregar Pieza (Ej: RTX 3060)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                  onPressed: _addData,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: myNodes
                  .toList()
                  .map(
                    (item) => Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.computer,
                            color: Colors.blueAccent),
                        title: Text(item,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}