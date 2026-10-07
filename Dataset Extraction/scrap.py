import requests
from bs4 import BeautifulSoup
import json
import os

# List of URLs to scrape (Keys before colon will be used as filenames)
urls = {
    "Admission": "https://www.ualberta.ca/en/computing-science/graduate-studies/programs-and-admissions/applications-and-admissions/index.html",
    "Adam_White": "https://apps.ualberta.ca/directory/person/amw8",
    "Irene_Cheng": "https://apps.ualberta.ca/directory/person/locheng",
    "Anup_Basu": "https://apps.ualberta.ca/directory/person/basu",
    "Nidhi_Hegde": "https://apps.ualberta.ca/directory/person/nidhih",
    "Rupam_Mahmood": "https://apps.ualberta.ca/directory/person/ashique",
    "Tution_Fees": "https://www.ualberta.ca/en/admissions-programs/tuition/index.html",
    "Multimedia": "https://www.ualberta.ca/en/computing-science/graduate-studies/programs-and-admissions/multimedia.html"
}

# Create output directory
output_dir = "scraped_pages"
os.makedirs(output_dir, exist_ok=True)

# Function to fetch webpage content
def fetch_webpage(url):
    response = requests.get(url)
    if response.status_code == 200:
        return BeautifulSoup(response.text, "html.parser")
    else:
        print(f"Failed to fetch {url}")
        return None

# Extract **ALL** text from page (headings, paragraphs, tables, links)
def extract_content(soup):
    sections = {}

    # Extract headings, paragraphs, and list items
    content = []
    for element in soup.find_all(["h1", "h2", "h3", "h4", "p", "li"]):
        text = element.get_text(strip=True)
        if text:
            content.append(text)

    sections["Text Content"] = "\n".join(content)

    # Extract tables 
    tables = soup.find_all("table")
    table_data = []
    for table in tables:
        rows = table.find_all("tr")
        table_dict = []
        for row in rows:
            cells = row.find_all(["th", "td"])
            row_data = [cell.get_text(strip=True) for cell in cells]
            if row_data:
                table_dict.append(" | ".join(row_data))
        if table_dict:
            table_data.append("\n".join(table_dict))  # Convert each table to a formatted string

    if table_data:
        sections["Tables"] = "\n\n".join(table_data)

    # Extract links (including PDFs, DOCs, and external references)
    links = []
    for link in soup.find_all("a", href=True):
        href = link["href"]
        text = link.get_text(strip=True)
        if href.endswith((".pdf", ".doc", ".docx")):
            links.append(f"{text} (Download: {href})")
        else:
            links.append(f"{text} (URL: {href})")

    if links:
        sections["Links"] = "\n".join(links)

    return sections

# Save extracted content to a text file
def save_to_text_file(sections, filename):
    with open(filename, "w", encoding="utf-8") as f:
        for title, content in sections.items():
            f.write(f"{title}:\n{content}\n\n")
    print(f"Saved text file: {filename}")

# Run the scraper for multiple URLs
for filename_prefix, url in urls.items():
    soup = fetch_webpage(url)
    if soup:
        structured_data = extract_content(soup)

        # Generate filenames using the key before the colon
        text_filename = os.path.join(output_dir, f"{filename_prefix}.txt")
        json_filename = os.path.join(output_dir, f"{filename_prefix}.json")

        # Save text file
        save_to_text_file(structured_data, text_filename)

        # Save JSON file
        with open(json_filename, "w", encoding="utf-8") as f:
            json.dump(structured_data, f, indent=4)

        print(f"Saved JSON file: {json_filename}")

print(" All webpages scraped and saved successfully!")
