import urllib.request
import json
import mimetypes
import os

def upload_image(filepath, url='http://127.0.0.1:5050/api/predict'):
    filename = os.path.basename(filepath)
    content_type, _ = mimetypes.guess_type(filepath)
    
    with open(filepath, 'rb') as f:
        file_data = f.read()

    boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
    data = []
    data.append(f'--{boundary}')
    data.append(f'Content-Disposition: form-data; name="image"; filename="{filename}"')
    data.append(f'Content-Type: {content_type}')
    data.append('')
    data.append(file_data)
    data.append(f'--{boundary}--')
    data.append('')
    
    # We need to manually construct the bytes body because it contains binary image data
    body = bytearray()
    for item in data:
        if isinstance(item, str):
            body.extend(item.encode('utf-8'))
            body.extend(b'\r\n')
        else:
            body.extend(item)
            body.extend(b'\r\n')

    req = urllib.request.Request(url, data=body)
    req.add_header('Content-Type', f'multipart/form-data; boundary={boundary}')
    
    try:
        response = urllib.request.urlopen(req)
        return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        raw = e.read().decode('utf-8')
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            print("HTTP 500 error! Raw HTML:")
            print(raw[:1000])
            return {}

print("Testing valid fundus image...")
res1 = upload_image(r"d:\SIH-26038\messidor-2\preprocess\20051020_43808_0100_PP.png")
print("Response success:", res1.get('success', False))
if not res1.get('success', False):
    print("Error:", res1.get('errorMessage', 'None'))

print("\nTesting non-retinal image (landscape)...")
res2 = upload_image(r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\landscape_1789452071464.png")
print("Response success:", res2.get('success', False))
print("ErrorType:", res2.get('errorType', 'None'))
print("ErrorMessage:", res2.get('errorMessage', 'None'))
