import requests
from bs4 import BeautifulSoup
import json

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
    items = []
    
    # Esta clase suele ser el contenedor de los resultados de búsqueda de Amazon
    # NOTA: Amazon cambia sus clases HTML constantemente, si el script falla, hay que inspeccionar la web y actualizar esto.
    results = soup.find_all('div', {'data-component-type': 's-search-result'})
    
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
            
    return items

if __name__ == "__main__":
    print("Iniciando Amazon Scraper Bot...")
    query = "AMD Ryzen 5 5600X"
    resultados = scrape_amazon(query)
    
    # Guardar en un JSON para que la app de Flutter lo pueda leer como un servicio API
    with open('precios_amazon.json', 'w', encoding='utf-8') as f:
        json.dump(resultados, f, ensure_ascii=False, indent=4)
        
    print(f"\nScraping completado. Se encontraron {len(resultados)} resultados.")
    for res in resultados:
        print(f"- {res['nombre'][:50]}... : {res['precio']}")
