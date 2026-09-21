import urllib.request, json, os
filepath=r'd:\SIH-26038\messidor-2\preprocess\20051020_43808_0100_PP.png'
boundary='----WebKitFormBoundary7MA4YWxkTrZu0gW'
body=(f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{os.path.basename(filepath)}"\r\nContent-Type: image/png\r\n\r\n').encode('utf-8') + open(filepath, 'rb').read() + f'\r\n--{boundary}--\r\n'.encode('utf-8')
req=urllib.request.Request('http://127.0.0.1:5050/api/predict', body, {'Content-Type': f'multipart/form-data; boundary={boundary}'})
try:
    print(json.loads(urllib.request.urlopen(req).read().decode('utf-8')))
except Exception as e:
    print(e.read().decode('utf-8'))
