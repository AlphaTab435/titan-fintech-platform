from fastapi import FastAPI
import random
import os

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "Titan Fintech API is Online", "version": "1.0.0"}

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