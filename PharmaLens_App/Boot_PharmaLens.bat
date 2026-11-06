@echo off
:: Hardcode the API key for automated background booting
set GEMINI_API_KEY="YOUR_API_KEY_HERE"

:: Change directory to the backend folder
cd backend

:: Start the FastAPI server
uvicorn main:app --port 8000