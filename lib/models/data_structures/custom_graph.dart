class CustomGraph {
  // Diccionario principal: guarda el nombre y la lista de conexiones
  Map<String, List<String>> adjList = {};

  // Agrega un personaje nuevo al grafo
  void insertar(String data) {
    // Verifica que no exista ya, para no borrar por accidente si ya tenía datos
    if (!adjList.containsKey(data)) {
      adjList[data] = []; // Lo guarda con una lista de conexiones vacía
    }
  }

  // Borra a un personaje de todos lados
  void eliminar(String data) {
    // 1. Lo quita de la lista principal
    adjList.remove(data);
    
    // 2. Revisa a los demás y lo borra de sus listas para que no queden errores
    for (var conexiones in adjList.values) {
      conexiones.remove(data);
    }
  }

  // Avisa si el personaje existe (true) o no (false)
  bool buscar(String data) {
    return adjList.containsKey(data);
  }

  // Une a dos personajes (crea la línea entre ellos)
  void agregarConexion(String origen, String destino) {
    // Solo los conecta si se asegura de que ambos ya están guardados
    if (adjList.containsKey(origen) && adjList.containsKey(destino)) {
      adjList[origen]!.add(destino);
    }
  }
}