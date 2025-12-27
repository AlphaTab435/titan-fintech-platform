from fastapi import FastAPI
import random
import os

app = FastAPI()

@app.get("/")
def read_root():
    version = os.getenv("APP_VERSION", "1.0.0")
    return {"status": "Titan Fintech API is Online", "version": version}

@app.get("/transaction")
def create_transaction():
    # Simulate processing
    amount = random.randint(10, 1000)
    return {
        "transaction_id": hex(random.getrandbits(128)),
        "amount": amount,
        "currency": "USD",
        "status": "APPROVED",
        "processed_by": os.getenv("HOSTNAME", "unknown-pod")
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}