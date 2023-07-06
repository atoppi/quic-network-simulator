import os
import sys
import pathlib
import json

client_qlog_path = pathlib.Path(sys.argv[1])
server_qlog_path = pathlib.Path(sys.argv[2])
client_pcap_path = os.path.join(client_qlog_path.parent.parent.absolute(), "client.pcap")
server_pcap_path = os.path.join(server_qlog_path.parent.parent.absolute(), "server.pcap")

file_client = client_qlog_path.open("r")
file_server = server_qlog_path.open("r")

sent_count = 0
recv_count = 0
num = 0
sum_rtt = 0

data = json.load(file_client)
events = data["traces"][0]["events"]
for event in events:
	if "packet_received" in event["name"]:
		recv_count += 1
	if "data" in event and "latest_rtt" in event["data"]:
		num += 1
		sum_rtt += event["data"]["latest_rtt"]

data = json.load(file_server)
events = data["traces"][0]["events"]
for event in events:
	if "packet_sent" in event["name"]:
		sent_count += 1

# Packet loss
packet_loss = round (100 * ((sent_count - recv_count) / sent_count), 2)

# Average RTT 
avg_rtt = round (sum_rtt / num, 2)

# Throughput
throughput = os.popen('%s %s' % (os.path.join(pathlib.Path(__file__).parent.absolute(), 'get_throughput.sh'), client_pcap_path)).read().strip()

print("loss:", packet_loss,"%")
print("rtt:", avg_rtt, "ms")
print("throughput:", throughput, "Mbps")
