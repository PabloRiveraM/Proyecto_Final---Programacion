import './item_model.dart';

class CustomGraph {
  // Diccionario principal: guarda el nombre y su lista de conexiones
  Map<ItemModel, List<ItemModel>> adjList = {};

  // Agrega un personaje nuevo al grafo
  void insertar(ItemModel data) {
    // Verifico que no exista ya, para no borrar por accidente si ya tenía datos
    if (!adjList.containsKey(data)) {
      adjList[data] = []; // Lo guardo con una lista de conexiones vacía
    }
  }

  // Borra a un personaje de todos lados
  void eliminar(ItemModel data) {
    // 1. Lo quito de la lista principal
    adjList.remove(data);
    
    // 2. Reviso a los demás y lo borro de sus listas para que no queden errores
    for (var conexiones in adjList.values) {
      conexiones.remove(data);
    }
  }

  // Me avisa si el personaje existe (true) o no (false)
  bool buscar(ItemModel data) {
    return adjList.containsKey(data);
  }

  // Une a dos personajes (crea la línea entre ellos)
  void agregarConexion(ItemModel origen, ItemModel destino) {
    // Solo los conecto si me aseguro de que ambos ya están guardados
    if (adjList.containsKey(origen) && adjList.containsKey(destino)) {
      adjList[origen]!.add(destino);
    }
  }
}