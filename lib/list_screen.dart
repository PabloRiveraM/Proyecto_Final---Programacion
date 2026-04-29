import '../models/data_structures/custom_list.dart';
import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  // Instanciamos tu estructura de datos
  CustomLinkedList<String> myNodes = CustomLinkedList<String>();
  final TextEditingController _controller = TextEditingController();

  void _addData() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        myNodes.insert(_controller.text);
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Módulo: Lista Enlazada")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Nuevo Nodo'),
                  ),
                ),
                IconButton(icon: Icon(Icons.add), onPressed: _addData),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: myNodes.toList().map((item) => ListTile(
                leading: Icon(Icons.link),
                title: Text(item),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => myNodes.delete(item)),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}