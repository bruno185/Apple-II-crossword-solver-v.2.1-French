# FINAL
# Programme écrit par chatGPT, suivant un cahier des charges (cf. cahier des charges.txt)
# Plusieurs itérations ont été ncessaires

import os
import shutil
import time
import math

def main():
    # Mesure du temps total
    start_time = time.time()

    # Détruire et recréer les répertoires L1 à LF
    for i in range(1, 16):
        dir_name = f"L{hex(i)[2:].upper()}"
        if os.path.exists(dir_name):
            shutil.rmtree(dir_name)  # Supprime le répertoire, même s'il n'est pas vide
        os.makedirs(dir_name)  # Recrée le répertoire

    # Lire le fichier words.txt et créer les fichiers WORDS
    with open("words.txt", "r") as word_file:
        words = word_file.read().split()  # Lecture et séparation des mots

    for i in range(1, 16):
        dir_name = f"L{hex(i)[2:].upper()}"
        with open(os.path.join(dir_name, "WORDS"), "wb") as words_file:
            for word in words:
                if len(word) == i:
                    words_file.write(word.encode('ascii') + b'\x00' * (16 - len(word)))  # Compléter à 16 octets avec des octets \x00

    # Traiter les répertoires L2 à LF
    for i in range(2, 16):
        dir_name = f"L{hex(i)[2:].upper()}"
        print(f"Traitement du répertoire {dir_name}...")
        start_dir_time = time.time()

        words_path = os.path.join(dir_name, "WORDS")
        if not os.path.exists(words_path):
            continue

        # Lire les mots dans WORDS
        with open(words_path, "rb") as words_file:
            words_data = words_file.read()

        num_words = len(words_data) // 16

        # Créer un dictionnaire pour regrouper les bits par fichier
        bit_data = {}

        for word_index in range(num_words):
            word = words_data[word_index * 16:(word_index + 1) * 16].rstrip(b'\x00').decode('ascii')
            for pos, letter in enumerate(word):
                file_name = f"{letter.upper()}{hex(pos + 1)[2:].upper()}"
                if file_name not in bit_data:
                    bit_data[file_name] = bytearray(math.ceil(num_words / 8))

                byte_index = word_index // 8
                bit_index = word_index % 8
                bit_data[file_name][byte_index] |= (1 << bit_index)

        # Écrire les fichiers binaires regroupés
        for file_name, data in bit_data.items():
            file_path = os.path.join(dir_name, file_name)
            if not os.path.exists(file_path):
                with open(file_path, "wb") as bin_file:
                    bin_file.write(data)

        # Créer le fichier L
        l_file_path = os.path.join(dir_name, "L")
        with open(l_file_path, "wb") as l_file:
            num_bytes = math.ceil(num_words / 8)
            full_bytes = b"\xFF" * (num_words // 8)
            remaining_bits = num_words % 8

            if remaining_bits:
                last_byte = (1 << remaining_bits) - 1  # Crée les bits restants à 1
                l_file.write(full_bytes + last_byte.to_bytes(1, "big"))
            else:
                l_file.write(full_bytes)

        # Mesurer et afficher le temps pour le répertoire
        dir_time = time.time() - start_dir_time
        print(f"Répertoire {dir_name} traité en {dir_time:.2f} secondes.")

    # Afficher le temps total
    total_time = time.time() - start_time
    print(f"Temps total d'exécution : {total_time:.2f} secondes.")

if __name__ == "__main__":
    main()
