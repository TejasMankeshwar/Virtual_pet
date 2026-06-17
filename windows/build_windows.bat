@echo off
echo Installing requirements...
pip install -r requirements.txt
pip install pyinstaller

echo Building Virtual Pet...
pyinstaller --noconfirm --onedir --windowed --add-data ".:."  main.py

echo Build complete! You can find the executable in the 'dist/main' folder.
pause
