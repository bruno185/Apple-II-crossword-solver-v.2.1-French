# Ce programme Python a été écrit par DeepSeek
# Il fallu de nombreuses itérations et demandes de corrections à Deepseek 
# pour que l'IA produise un programme correct et performant.

import os
import time
import shutil
from collections import defaultdict

# Fonction pour convertir un nombre en hexadécimal sans le préfixe '0x'
def to_hex(n):
    return hex(n)[2:].upper()

# Fonction pour détruire et recréer les répertoires L1 à LF
def recreate_directories():
    for i in range(1, 16):
        dir_name = f"L{to_hex(i)}"
        if os.path.exists(dir_name):
            shutil.rmtree(dir_name)  # Supprime le répertoire et son contenu
        os.makedirs(dir_name)  # Recrée le répertoire

# Fonction pour lire les mots du fichier words.txt et les répartir dans les répertoires L1 à LF
def distribute_words():
    # Ouvrir le fichier words.txt une seule fois
    with open("words.txt", "r") as file:
        words = file.read().splitlines()  # Lit tous les mots du fichier

    # Dictionnaire pour regrouper les mots par longueur
    words_by_length = defaultdict(list)

    # Regrouper les mots par leur longueur
    for word in words:
        length = len(word)
        if length == 0 or length > 15:
            continue  # Ignore les mots vides ou trop longs
        words_by_length[length].append(word)

    # Écrire les mots dans les fichiers WORDS des répertoires correspondants
    for length, word_list in words_by_length.items():
        dir_name = f"L{to_hex(length)}"
        with open(f"{dir_name}/WORDS", "ab") as f:  # Ouvre le fichier WORDS en mode ajout binaire
            for word in word_list:
                padded_word = word.ljust(16, '\x00')  # Complète le mot avec des octets nuls
                f.write(padded_word.encode('utf-8'))  # Écrit le mot dans le fichier

# Fonction pour créer les fichiers binaires basés sur les lettres et leurs positions
def create_letter_files():
    for i in range(2, 16):
        dir_name = f"L{to_hex(i)}"
        words_file = f"{dir_name}/WORDS"
        if not os.path.exists(words_file):
            continue

        # Dictionnaire pour stocker les bits en mémoire
        bitmaps = defaultdict(lambda: bytearray())

        with open(words_file, "rb") as f:
            word_count = 0
            while True:
                word = f.read(16)  # Lit un mot de 16 octets
                if not word:
                    break
                word_count += 1
                for pos, char in enumerate(word[:16], start=1):  # Parcourt chaque lettre et sa position
                    if char == 0:
                        continue
                    file_name = f"{chr(char)}{to_hex(pos)}"
                    # Calcule l'index du bit à mettre à 1
                    byte_pos = (word_count - 1) // 8
                    bit_pos = (word_count - 1) % 8
                    # Agrandit le bytearray si nécessaire
                    while len(bitmaps[file_name]) <= byte_pos:
                        bitmaps[file_name].append(0)
                    # Met le bit à 1
                    bitmaps[file_name][byte_pos] |= (1 << bit_pos)

        # Écrit les bitmaps dans les fichiers
        for file_name, bitmap in bitmaps.items():
            with open(f"{dir_name}/{file_name}", "wb") as letter_file:
                letter_file.write(bitmap)

# Fonction pour créer le fichier "L" dans chaque répertoire
def create_L_files():
    for i in range(2, 16):
        dir_name = f"L{to_hex(i)}"
        words_file = f"{dir_name}/WORDS"
        if not os.path.exists(words_file):
            continue

        with open(words_file, "rb") as f:
            word_count = sum(1 for _ in f) // 16  # Compte le nombre de mots

        # Crée un fichier "L" avec des bits à 1
        with open(f"{dir_name}/L", "wb") as l_file:
            l_file.write(bytes([255] * ((word_count + 7) // 8)))  # Remplit le fichier avec des bits à 1

# Fonction principale
def main():
    start_time = time.time()  # Démarre le chronomètre

    recreate_directories()
    print("dirs ok")
    distribute_words()
    print("words ok")
    create_letter_files()
    print("letters ok")
    create_L_files()
    print("L files ok")

    total_time = time.time() - start_time  # Calcule le temps total
    print(f"Temps total d'exécution : {total_time:.2f} secondes")

if __name__ == "__main__":
    main()