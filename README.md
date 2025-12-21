pip install -r requirements.txt

uvicorn main:app --host 0.0.0.0 --port 80
uvicorn main:app --reload --host 127.0.0.1 --port 80
