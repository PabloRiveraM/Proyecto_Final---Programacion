import requests
from bs4 import BeautifulSoup
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

def scrape_amazon(search_query):
    # Amazon tiene medidas anti-bots fuertes, así que necesitamos simular un navegador real
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
        'Accept-Language': 'es-ES, es;q=0.9, en-US;q=0.8, en;q=0.7'
    }
    
    url = f"https://www.amazon.com/s?k={search_query.replace(' ', '+')}"
    print(f"Buscando en: {url}")
    
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Error al conectar con Amazon (Status Code: {response.status_code}). Es posible que un CAPTCHA haya bloqueado la solicitud.")
        return []

    soup = BeautifulSoup(response.content, 'html.parser')
    page_title = soup.title.text.strip() if soup.title else "Sin Título"
    
    # Esta clase suele ser el contenedor de los resultados de búsqueda de Amazon
    results = soup.find_all('div', {'data-component-type': 's-search-result'})
    
    print(f"  -> Título de la página de Amazon: '{page_title}'")
    print(f"  -> Resultados encontrados: {len(results)}")
    
    if "api-services" in page_title.lower() or "robot" in page_title.lower() or "captcha" in page_title.lower() or "automated" in page_title.lower():
        print("  [⚠️ ALERTA] Amazon detectó la solicitud como un bot (CAPTCHA / Robot Check).")

    items = []
    for item in results[:5]:  # Obtener los top 5 resultados
        title_element = item.find('h2', class_='a-size-mini')
        price_whole = item.find('span', class_='a-price-whole')
        price_fraction = item.find('span', class_='a-price-fraction')
        link_element = item.find('a', class_='a-link-normal')

        if title_element and price_whole:
            title = title_element.text.strip()
            price = f"${price_whole.text}{price_fraction.text if price_fraction else '00'}"
            link = f"https://www.amazon.com{link_element['href']}" if link_element else ""
            
            items.append({
                "nombre": title,
                "precio": price,
                "enlace": link
            })
            
    print(f"  -> Elementos válidos procesados (con precio y título): {len(items)}")
    return items

@app.route('/search', methods=['GET'])
def search():
    query = request.args.get('q')
    if not query:
        return jsonify({"error": "No search query provided"}), 400
    
    resultados = scrape_amazon(query)
    return jsonify(resultados)

if __name__ == "__main__":
    print("Iniciando Amazon Scraper Bot (Servidor Flask)...")
    app.run(host='0.0.0.0', port=5000, debug=True)
