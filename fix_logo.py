import re

with open('dashboard/index.html', 'r', encoding='utf-8') as f:
    html_index = f.read()

# Grab the exact img tag for the logo
img_tag_match = re.search(r'<img class="logo-icon" src="data:image/png;base64,[^"]+"[^>]*>', html_index)
if not img_tag_match:
    print("Could not find logo in index.html")
    exit(1)

img_tag = img_tag_match.group(0)

for filename in ['dashboard/cases.html', 'dashboard/adaptation.html']:
    with open(filename, 'r', encoding='utf-8') as f:
        html_content = f.read()
    
    # Replace the existing img tag with the one from index.html
    html_content = re.sub(r'<img class="logo-icon" src="data:image/png;base64,[^"]+"[^>]*>', img_tag, html_content)
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(html_content)

print("Done replacing logos")
