import urllib.request
import json
import os

def upload_image(filepath, url='http://127.0.0.1:5050/api/predict'):
    filename = os.path.basename(filepath)
    boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
    
    with open(filepath, 'rb') as f:
        file_data = f.read()
    
    body = (
        f'--{boundary}\r\n'
        f'Content-Disposition: form-data; name="image"; filename="{filename}"\r\n'
        f'Content-Type: image/png\r\n\r\n'
    ).encode('utf-8') + file_data + f'\r\n--{boundary}--\r\n'.encode('utf-8')
    
    req = urllib.request.Request(url, body, {
        'Content-Type': f'multipart/form-data; boundary={boundary}'
    })
    
    try:
        response = urllib.request.urlopen(req, timeout=30)
        return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        raw = e.read().decode('utf-8')
        try:
            return json.loads(raw)
        except:
            return {'error': f'HTTP {e.code}', 'raw': raw[:200]}
    except Exception as e:
        return {'error': str(e)}

# Test 1: Valid fundus
print("TEST 1: Valid fundus image")
res = upload_image(r"d:\SIH-26038\messidor-2\preprocess\20051020_43808_0100_PP.png")
print(f"  success={res.get('success')} errorType={res.get('errorType', 'NONE')}")
if res.get('success'):
    print(f"  grade={res.get('grade')} referable={res.get('referable')}")
print()

# Test 2: Landscape (must be rejected)
landscape = r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\landscape_1789452071464.png"
if os.path.exists(landscape):
    print("TEST 2: Landscape (scenery)")
    res = upload_image(landscape)
    print(f"  success={res.get('success')} errorType={res.get('errorType', 'NONE')}")
    print()

# Test 3: Face (must be rejected)
face = r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\human_face_1789452046787.png"
if os.path.exists(face):
    print("TEST 3: Human face")
    res = upload_image(face)
    print(f"  success={res.get('success')} errorType={res.get('errorType', 'NONE')}")
    print()

# Test 4: Another valid fundus
print("TEST 4: Another valid fundus")
res = upload_image(r"d:\SIH-26038\messidor-2\preprocess\20051020_44261_0100_PP.png")
print(f"  success={res.get('success')} errorType={res.get('errorType', 'NONE')}")
if res.get('success'):
    print(f"  grade={res.get('grade')} referable={res.get('referable')}")
print()

# Test 5: Controlled Adaptation Endpoint
print("TEST 5: Controlled Adaptation API")
try:
    req = urllib.request.Request('http://127.0.0.1:5050/api/adaptation')
    response = urllib.request.urlopen(req, timeout=10)
    data = json.loads(response.read().decode('utf-8'))
    print(f"  success=True decision={data.get('adaptation_status', {}).get('decision')}")
except Exception as e:
    print(f"  success=False error={str(e)}")
print()
