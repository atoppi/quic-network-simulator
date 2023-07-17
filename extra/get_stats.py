import glob
import json
import os
import pathlib
import sys
import csv
import datetime

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

output_csv_file = str(server_results_path) + "/" + datetime.datetime.now().strftime("server_rtt_cwnd_%Y-%m-%d_%H-%M-%S.csv")

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
        writer = csv.writer(open(output_csv_file, "w"))
        curr_rtt_ms = 0
        curr_cwnd = 0
        first_time = 0.0
        curr_time = 0.0
        # Print first row on csv
        writer.writerow(["curr_time;curr_cwnd;curr_rtt_ms"])

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
                        curr_rtt_ms = event[3]["latest_rtt"]/1000 
                    if "cwnd" in event[3]:
                        curr_cwnd = event[3]["cwnd"]
                    if ("cwnd" in event[3] or "latest_rtt" in event[3]):
                        if first_time == 0:
                            first_time = event[0]
                        curr_time = (event[0] - first_time) / 1000000
                        curr_row = f"{curr_time:.6f};{curr_cwnd};{curr_rtt_ms:.3f}"
                        # Print curr_time, curr_cwnd, curr_rtt_ms on csv
                        writer.writerow([curr_row])
                else:
                    if "name" in event and "packet_sent" in event["name"]:
                        sent_count += 1
                    if "data" in event and "latest_rtt" in event["data"]:
                        samples_rtt += 1
                        sum_rtt += event["data"]["latest_rtt"]
                        curr_rtt_ms = event["data"]["latest_rtt"] 
                    if "data" in event and "cwnd" in event["data"]:
                        curr_cwnd = event["data"]["cwnd"] 
                    if "time" in event and ("cwnd" in event["data"] or "latest_rtt" in event["data"]):
                        if first_time == 0:
                            first_time = event["time"]
                        curr_time = (event["time"] - first_time) / 1000
                        curr_row = f"{curr_time:.6f};{curr_cwnd};{curr_rtt_ms:.3f}"
                        # Print curr_time, curr_cwnd, curr_rtt_ms on csv
                        writer.writerow([curr_row])
                
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
                    curr_rtt_ms = event["data"]["latest_rtt"] 
                if "data" in event and "congestion_window" in event["data"]:
                    curr_cwnd = event["data"]["congestion_window"] 
                if "data" in event and ("congestion_window" in event["data"] or "latest_rtt" in event["data"]):
                    if first_time == 0:
                            first_time = event["time"]
                    curr_time = (event["time"] - first_time) / 1000
                    curr_row = f"{curr_time:.6f};{curr_cwnd};{curr_rtt_ms:.3f}"
                    # Print curr_time, curr_cwnd, curr_rtt_ms on csv
                    writer.writerow([curr_row])

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
