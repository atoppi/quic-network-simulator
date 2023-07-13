import glob
import json
import os
import pathlib
import sys

client_results_path = pathlib.Path(sys.argv[1]).absolute()
server_results_path = pathlib.Path(sys.argv[2]).absolute()

client_qlog_path = pathlib.Path(
    os.path.join(
        client_results_path,
        glob.glob(pathname='./qlog/*.*log', root_dir=client_results_path)[0]))
server_qlog_path = pathlib.Path(
    os.path.join(
        server_results_path,
        glob.glob(pathname='./qlog/*.*log', root_dir=server_results_path)[0]))
client_pcap_path = pathlib.Path(
    os.path.join(
        client_results_path,
        "client.pcap"))
server_pcap_path = pathlib.Path(
    os.path.join(
        server_results_path,
        "server.pcap"))

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
            trace = data["traces"][0]
            if "vantage_point" in trace and "name" in trace["vantage_point"]:
                client_name = trace["vantage_point"]["name"]
            events = trace["events"]
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
                if ("trace" in event and "vantage_point" in event["trace"]
                        and "name" in event["trace"]["vantage_point"]):
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
            trace = data["traces"][0]
            if "vantage_point" in trace and "name" in trace["vantage_point"]:
                server_name = trace["vantage_point"]["name"]
            events = trace["events"]
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
                if ("trace" in event
                        and "name" in event["trace"]["vantage_point"]):
                    server_name = event["trace"]["vantage_point"]["name"]
                if "name" in event and "packet_sent" in event["name"]:
                    sent_count += 1
                if "data" in event and "latest_rtt" in event["data"]:
                    samples_rtt += 1
                    sum_rtt += event["data"]["latest_rtt"]

if (client_qlog_path.is_file() and server_qlog_path.is_file()):
    # Packet loss
    packet_loss = round(100 * ((sent_count - recv_count) / sent_count), 2)

    # Average RTT
    avg_rtt = round(sum_rtt / samples_rtt, 2)
else:
    packet_loss = "-"
    avg_rtt = "-"

# Throughput
th_script_path = os.path.join(
    pathlib.Path(__file__).parent,
    'get_throughput.sh')
avg_throughput = os.popen(
    '%s %s' % (th_script_path, client_pcap_path)).read().strip()

print('%s;%s;%s' % (packet_loss, avg_rtt, avg_throughput))
