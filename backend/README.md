# Scraping de Precios (Backend)

Este directorio contiene los scripts del lado del servidor para consultar precios actualizados en tiendas online. Dado que intentar hacer Scraping directamente desde la aplicación en Flutter (App Móvil) puede generar problemas de red (CORS en la web o bloqueos por IP), la mejor arquitectura es tener este script como un intermediario.

## 🛠 Requisitos Previos

Necesitas tener Python instalado en tu computadora y la librería `BeautifulSoup4` y `requests`.

1. Instala las dependencias ejecutando en tu terminal:
   ```bash
   pip install requests beautifulsoup4
   ```

## 🚀 Uso

1. Ejecuta el script de scraping de Amazon:
   ```bash
   python amazon_scraper.py
   ```
2. El script simulará un navegador real, buscará el componente en Amazon (ej. "AMD Ryzen 5 5600X"), e imprimirá los precios.
3. Se generará un archivo llamado `precios_amazon.json` con los resultados.

## 🔄 Integración con Flutter

Este archivo `precios_amazon.json` puede ser expuesto a través de una API REST muy sencilla usando Python (con un framework como Flask o FastAPI), para que la aplicación en Flutter (nuestro proyecto principal) simplemente consuma la URL y muestre las tiendas sugeridas en la pantalla de la Wishlist o Ensamble.
