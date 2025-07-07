# q2.py
import socket

HOST = "127.0.0.1"
PORT = 8080

try:
    sock = socket.create_connection((HOST, PORT), timeout=2)
    print("[✓] Connected to Tcpuart at 127.0.0.1:8080")
    
    while True:
        data = sock.recv(1)  # Read 1 byte
        if data:
            byte_val = data[0] & 0x7F  # Strip MSB if needed
            print(byte_val)
except Exception as e:
    print(f"[!] Error: {e}")
