from fastapi import FastAPI, Request
from datetime import datetime, timezone

app = FastAPI()

@app.get("/healthz")
def healthz():
    return {"ok": True, "service": "cyqu-demo", "host": "demo.cyqu.org",
            "ts": datetime.now(timezone.utc).isoformat()}

@app.get("/about")
def about(req: Request):
    return {
        "service": "cyqu-demo",
        "negotiated_group": req.headers.get("x-tls-group", "unknown"),
        "ts": datetime.now(timezone.utc).isoformat(),
    }

