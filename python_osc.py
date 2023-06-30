from pythonosc import udp_client

# Specify the IP address and port number
ip = "127.0.0.1"
port = 8000

# Create a client
client = udp_client.SimpleUDPClient(ip, port)  

# Send an OSC message
client.send_message("/test", [123, "hello"])