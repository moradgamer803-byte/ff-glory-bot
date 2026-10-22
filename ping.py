import os, time, urllib.request

url = (os.environ.get("RENDER_EXTERNAL_URL") or "").rstrip("/")
while True:
    time.sleep(200)
    if not url:
        continue
    try:
        urllib.request.urlopen(url + "/api/ping", timeout=120).read()
        print("[keepalive] ping ok", flush=True)
    except Exception as e:
        print("[keepalive] ping fail:", repr(e)[:120], flush=True)
