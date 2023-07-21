import glob
import json
import os
import pathlib
import sys
import csv

client_results_path = pathlib.Path(sys.argv[1]).absolute()
server_results_path = pathlib.Path(sys.argv[2]).absolute()

client_qlogs = glob.glob(pathname="./qlog/*.*log", root_dir=client_results_path)
client_qlog_path = None
if client_qlogs:
    client_qlog_path = pathlib.Path(
        os.path.join(
            client_results_path,
            client_qlogs[0],
        )
    )

server_qlogs = glob.glob(pathname="./qlog/*.*log", root_dir=server_results_path)
server_qlog_path = None
if server_qlogs:
    server_qlog_path = pathlib.Path(
        os.path.join(
            server_results_path,
            server_qlogs[0],
        )
    )

sent_count = 0
recv_count = 0
samples_rtt = 0
sum_rtt = 0
client_name = ""
server_name = ""

server_stats_csv_file_path = pathlib.Path(
    os.path.join(server_results_path, "server_rtt_cwnd.csv")
)

if client_qlog_path is not None and client_qlog_path.is_file():
    with open(client_qlog_path) as file_client:
        if client_qlog_path.suffix == ".qlog":
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
        elif client_qlog_path.suffix == ".sqlog":
            while True:
                line = file_client.readline().strip()
                if not line:
                    break
                event = json.loads(line)
                if (
                    "trace" in event
                    and "vantage_point" in event["trace"]
                    and "name" in event["trace"]["vantage_point"]
                ):
                    client_name = event["trace"]["vantage_point"]["name"]
                if "name" in event and "packet_received" in event["name"]:
                    recv_count += 1

if server_qlog_path is not None and server_qlog_path.is_file():
    with (
        open(server_qlog_path) as file_server,
        open(server_stats_csv_file_path, "w") as csv_file,
    ):
        writer = csv.writer(csv_file, delimiter=";")
        # Print first row on csv
        writer.writerow(["curr_time", "curr_cwnd", "curr_rtt_ms"])
        curr_rtt = 0
        curr_cwnd = 0
        first_time = 0
        curr_time = 0
        if server_qlog_path.suffix == ".qlog":
            data = json.load(file_server)
            is_picoquic = False
            if "title" in data and data["title"] == "picoquic":
                is_picoquic = True
            trace = data["traces"][0]
            if "vantage_point" in trace and "name" in trace["vantage_point"]:
                server_name = trace["vantage_point"]["name"]
            events = trace["events"]
            for event in events:
                rtt_sampled = False
                cwnd_sampled = False
                if is_picoquic:
                    if "packet_sent" in event[2]:
                        sent_count += 1
                    if "latest_rtt" in event[3]:
                        samples_rtt += 1
                        curr_rtt = event[3]["latest_rtt"]
                        sum_rtt += curr_rtt
                        rtt_sampled = True
                    if "cwnd" in event[3]:
                        curr_cwnd = event[3]["cwnd"]
                        cwnd_sampled = True
                    if rtt_sampled and cwnd_sampled:
                        sample_time = event[0]
                        if first_time == 0:
                            first_time = sample_time
                        curr_time = sample_time - first_time
                        # Print curr_time, curr_cwnd, curr_rtt_ms on csv
                        writer.writerow(
                            [
                                f"{curr_time/1000000:.6f}",
                                curr_cwnd,
                                f"{curr_rtt/1000:.3f}",
                            ]
                        )
                else:
                    if "name" in event and "packet_sent" in event["name"]:
                        sent_count += 1
                    if "data" in event:
                        rtt_sampled = False
                        cwnd_sampled = False
                        if "latest_rtt" in event["data"]:
                            samples_rtt += 1
                            curr_rtt = event["data"]["latest_rtt"]
                            sum_rtt += curr_rtt
                            rtt_sampled = True
                        if "cwnd" in event["data"]:
                            curr_cwnd = event["data"]["cwnd"]
                            cwnd_sampled = True
                        if rtt_sampled and cwnd_sampled and "time" in event:
                            sample_time = event["time"]
                            if first_time == 0:
                                first_time = sample_time
                            curr_time = sample_time - first_time
                            # Print curr_time, curr_cwnd, curr_rtt_ms on csv
                            writer.writerow(
                                [
                                    f"{curr_time/1000:.6f}",
                                    curr_cwnd,
                                    f"{curr_rtt:.3f}",
                                ]
                            )
            if is_picoquic:
                sum_rtt = sum_rtt / 1000
        elif server_qlog_path.suffix == ".sqlog":
            while True:
                line = file_server.readline().strip()
                if not line:
                    break
                event = json.loads(line)
                if "trace" in event and "name" in event["trace"]["vantage_point"]:
                    server_name = event["trace"]["vantage_point"]["name"]
                if "name" in event and "packet_sent" in event["name"]:
                    sent_count += 1
                if "data" in event:
                    rtt_sampled = False
                    cwnd_sampled = False
                    if "latest_rtt" in event["data"]:
                        samples_rtt += 1
                        curr_rtt = event["data"]["latest_rtt"]
                        sum_rtt += curr_rtt
                        rtt_sampled = True
                    if "congestion_window" in event["data"]:
                        curr_cwnd = event["data"]["congestion_window"]
                        cwnd_sampled = True
                    if rtt_sampled and cwnd_sampled and "time" in event:
                        sample_time = event["time"]
                        if first_time == 0:
                            first_time = sample_time
                        curr_time = sample_time - first_time
                        # Print curr_time, curr_cwnd, curr_rtt_ms on csv
                        writer.writerow(
                            [
                                f"{curr_time/1000:.6f}",
                                curr_cwnd,
                                f"{curr_rtt:.3f}",
                            ]
                        )

if sent_count > 0 and recv_count > 0 and sum_rtt > 0 and samples_rtt > 0:
    # Packet loss
    packet_loss = round(100 * ((sent_count - recv_count) / sent_count), 2)

    # Average RTT
    avg_rtt = round(sum_rtt / samples_rtt, 2)
else:
    packet_loss = 0
    avg_rtt = 0

# Throughput
client_pcap_path = pathlib.Path(os.path.join(client_results_path, "client.pcap"))
server_pcap_path = pathlib.Path(os.path.join(server_results_path, "server.pcap"))
th_script_path = os.path.join(pathlib.Path(__file__).parent, "get_throughput.sh")
avg_throughput = os.popen("%s %s" % (th_script_path, client_pcap_path)).read().strip()

print("%s;%s;%s" % (packet_loss, avg_rtt, avg_throughput))
