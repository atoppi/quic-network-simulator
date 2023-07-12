import os
import sys
import pathlib
import json

client_qlog_path = pathlib.Path(sys.argv[1])
server_qlog_path = pathlib.Path(sys.argv[2])
client_pcap_path = os.path.join(client_qlog_path.parent.parent.absolute(), "client.pcap")
server_pcap_path = os.path.join(server_qlog_path.parent.parent.absolute(), "server.pcap")

sent_count = 0
recv_count = 0
samples_rtt = 0
sum_rtt = 0
client_name = ""
server_name = ""

if (client_qlog_path.is_file()):
	with open(client_qlog_path) as file_client:
		if client_qlog_path.suffix == '.qlog':
			data = json.load(file_client)
			is_picoquic = False
			if "title" in data and data["title"] == "picoquic":
				is_picoquic = True
			if "vantage_point" in data["traces"][0] and "name" in data["traces"][0]["vantage_point"]:
				client_name = data["traces"][0]["vantage_point"]["name"]
			events = data["traces"][0]["events"]
			for event in events:
				if is_picoquic:
					if "packet_received" in event[2]:
						recv_count += 1
				else:
					if "name" in event and "packet_received" in event["name"]:
						recv_count += 1
		elif client_qlog_path.suffix == '.sqlog':
			while True:
				line = file_client.readline().strip()
				if not line:
					break
				event = json.loads(line)
				if "trace" in event and "vantage_point" in event["trace"] and "name" in event["trace"]["vantage_point"]:
					client_name = event["trace"]["vantage_point"]["name"]
				if "name" in event and "packet_received" in event["name"]:
					recv_count += 1

if (server_qlog_path.is_file()):
	with open(server_qlog_path) as file_server:
		if server_qlog_path.suffix == '.qlog':
			data = json.load(file_server)
			is_picoquic = False
			if "title" in data and data["title"] == "picoquic":
				is_picoquic = True
			if "vantage_point" in data["traces"][0] and "name" in data["traces"][0]["vantage_point"]:
				server_name = data["traces"][0]["vantage_point"]["name"]
			events = data["traces"][0]["events"]
			for event in events:
				if is_picoquic:
					if "packet_sent" in event[2]:
						sent_count += 1
					if "latest_rtt" in event[3]:
						samples_rtt += 1
						sum_rtt += event[3]["latest_rtt"]/1000
				else:
					if "name" in event and "packet_sent" in event["name"]:
						sent_count += 1
					if "data" in event and "latest_rtt" in event["data"]:
						samples_rtt += 1
						sum_rtt += event["data"]["latest_rtt"]
		elif server_qlog_path.suffix == '.sqlog':
			while True:
				line = file_server.readline().strip()
				if not line:
					break
				event = json.loads(line)
				if "trace" in event and "name" in event["trace"]["vantage_point"]:
					server_name = event["trace"]["vantage_point"]["name"]
				if "name" in event and "packet_sent" in event["name"]:
					sent_count += 1
				if "data" in event and "latest_rtt" in event["data"]:
					samples_rtt += 1
					sum_rtt += event["data"]["latest_rtt"]

if (client_qlog_path.is_file() and server_qlog_path.is_file()):
	# Packet loss
	packet_loss = round (100 * ((sent_count - recv_count) / sent_count), 2)

	# Average RTT
	avg_rtt = round (sum_rtt / samples_rtt, 2)
else:
	packet_loss = "-"
	avg_rtt = "-"

# Throughput
avg_throughput = os.popen('%s %s' % (os.path.join(pathlib.Path(__file__).parent.absolute(), 'get_throughput.sh'), client_pcap_path)).read().strip()

#print("client name:", client_name)
#print("server name:", server_name)
#print("loss:", packet_loss,"%")
#print("avg rtt:", avg_rtt, "ms")
#print("avg throughput:", avg_throughput, "Mbps")

print('%s;%s;%s' % (packet_loss, avg_rtt, avg_throughput))
