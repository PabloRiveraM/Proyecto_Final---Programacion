# Proyecto Final Programación - PC Builder AI

Una aplicación desarrollada en Flutter que permite a los usuarios armar su PC ideal utilizando una Inteligencia Artificial con RAG (Retrieval-Augmented Generation) como motor de búsqueda y catálogo de componentes.

## 🛠 Arquitectura y Equipo

El proyecto fue construido de forma modular, dividiendo las estructuras de datos y funcionalidades entre los miembros del equipo:

### 1. Pablo (Arquitectura y RAG)
- Configuración inicial y repositorio en GitHub.
- Configuración y diseño del `ApiService` que conecta con la API de IA (Gemini).
- Validación y formateo de JSON para que toda la aplicación pueda interpretar el catálogo generado de forma dinámica.
- Code review y gestión principal de Pull Requests.

### 2. Marly (Gestión Lineal y Ensamble)
- **Lista Enlazada Simple (`CustomLinkedList`)**: Se utiliza para mantener el orden de las piezas del ensamble actual. Permite añadir piezas seleccionadas y mantener una secuencia iterativa.
- **Pila (`CustomStack`)**: Implementada para el historial de acciones, permitiendo la función "Deshacer" (LIFO - Last In, First Out) al construir el ensamble.

### 3. Diego (Catálogo, Análisis y Wishlist)
- **Árbol Binario de Búsqueda (`CustomTree`)**: Empleado para organizar el catálogo general de piezas. Agrupa lógicamente en subárboles las piezas de procesamiento (CPU, Motherboard) y piezas generales, permitiendo un recorrido *In-Order* para los filtros UI.
- **Cola (`CustomQueue`)**: Gestiona la Wishlist (Lista de Deseos) bajo el principio FIFO (First In, First Out). La primera pieza que se guarda es la primera sugerida para "Comprar".
- **Análisis de Datos**: Implementación visual con `fl_chart` para agrupar el costo del ensamble por categorías, usando la centralización de datos del `AppState`.

### 4. Jose (Búsqueda Avanzada y Grafo de Compatibilidad)
- **Tabla Hash (`CustomHashTable`)**: Estructura de encadenamiento (buckets) que permite una búsqueda instantánea `O(1)` por ID de pieza y una búsqueda lineal por nombre.
- **Grafo de Compatibilidad (`CustomGraph`)**: Los nodos representan conectores y estándares (AM4, LGA1700, DDR4, DDR5). Las aristas determinan si dos piezas son compatibles. Al agregar al ensamble, el grafo detecta cuellos de botella e incompatibilidades.

## 🚀 Tecnologías

- **Flutter / Dart**
- **fl_chart** (Gráficas)
- **Google Gemini API** (Catálogo Dinámico RAG)

## 📦 Ejecución

1. Clonar el repositorio.
2. Ejecutar `flutter pub get` para obtener las dependencias (como `fl_chart`).
3. Añadir la llave de la API de Gemini en `lib/services/api_services.dart` (o variable de entorno según aplique).
4. Ejecutar con `flutter run`.
