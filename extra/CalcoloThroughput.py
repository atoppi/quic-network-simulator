import os
import pandas as pd

# Percorso della Cartella contenente i file .pcap
#folder = "./path/to/file"
folder = "/home/atoppi/src/quic-network-simulator/logs/captures/aioquic/transfer"

# Creazione di un DataFrame vuoto per i risultati
results = []

# Ciclo per attraversare tutti i file .pcap nella cartella
for file in os.listdir(folder):
    if file.endswith(".pcap") and file.startswith("client"):
        # Esegue il comando tshark e salva l'output in un file di testo (si potrebbe anche evitare il salvataggio su testo omettendo la riga da -q in poi)
        os.system(f"tshark -z conv,udp -r {folder}/{file} -q > output.txt")

        # Esegue il comando tail, head, tr e awk per estrarre le informazioni desiderate dall'output prendendo l'ultima riga delle informazioni rilevata da tshark
        # e stampa solo i valori in riferimento alla posizione 5 ovvero la quantità di bytes trasferiti e numero 14 ovvero la durata della cattura
        result = os.popen("tail -2 output.txt | head -1 | tr -s ' ' | awk -F ' ' '{print $5 \",\" $14}'").read().strip()

        # Aggiunge il risultato alla lista dei risultati
        results.append({"File": file, "Risultato": result})

# Visto che il salvataggio lo si fa su un file excel si provvede alla creazione del DataFrame dai risultati
results_df = pd.DataFrame(results)

# import pdb
# pdb.set_trace()

# Calcola il throughput e aggiorna il DataFrame
results_df[['Bytes', 'Durata', 'Third']] = results_df['Risultato'].str.split(',', expand=True).astype(float)
results_df['Throughput'] = (results_df['Bytes'] / results_df['Durata']) * 8

# Rimuovi la colonna 'Risultato' dal DataFrame
results_df = results_df.drop(columns=['Risultato'])

# Salva il DataFrame nel file Excel "risultati.xlsx"
results_df.to_excel("risultati.xlsx", index=False)





