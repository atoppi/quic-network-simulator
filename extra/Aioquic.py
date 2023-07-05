import json
import csv
import os

client_path = "aioquic/qlog/Client/" #path per il qlog lato client
server_path = "aioquic/qlog/Server/" #path per il qlog lato server
output_filename = "RisultatiAioquic.csv"  # Nome del file CSV di output su cui memorizzare il risultato

# Apertura del file CSV di output una volta all'esterno del ciclo for
with open(output_filename, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['File', 'Packet Loss', 'RTT Medio'])

    for filename in os.listdir(client_path):
        # Consideriamo solo i file con estensione .qlog
        if filename.endswith(".qlog"):
            # Caricamento dei dati dal file sia server che client
            with open(os.path.join(client_path, filename), "r") as file_client, \
                 open(os.path.join(server_path, filename), "r") as file_server:

                # Inizializzazione dei contatori
                sent_count = 0
                recv_count = 0
                num = 0
                sum_rtt = 0

                # Lettura del file qlog client e aggiornamento del contatore recv_count per il client e sum_rtt
                data = json.load(file_client)
                events = data["traces"][0]["events"]
                for event in events:
                    if "packet_received" in event["name"]:
                        recv_count += 1
                    if "data" in event and "latest_rtt" in event["data"]:
                        num += 1
                        sum_rtt += event["data"]["latest_rtt"]

                # Lettura del file qlog server e aggiornamento dei contatori sent_count 
                data = json.load(file_server)
                events = data["traces"][0]["events"]
                for event in events:
                    if "packet_sent" in event["name"]:
                        sent_count += 1

                # Calcolo Packet loss
                packet_loss = round ((sent_count - recv_count) / sent_count * 100,3)

                # Calcolo RTT 
                rtt_medio = round (sum_rtt / num,3)

                # Scrittura dei risultati nel file CSV di output
                writer.writerow([filename, packet_loss, rtt_medio])

print(f"Risultati salvati correttamente nel file {output_filename}")