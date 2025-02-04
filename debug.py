# Programme généré et commenté par ChatGPT
def process_file(input_file, output_file):
    # Ouvre le fichier en lecture et crée un fichier de sortie en écriture
    with open(input_file, 'r', encoding='utf-8') as infile, open(output_file, 'w', encoding='utf-8') as outfile:
        lines = infile.readlines()
        i = 0  # Initialise l'index pour parcourir les lignes du fichier
        
        while i < len(lines):  # Boucle sur toutes les lignes du fichier
            line = lines[i].strip()  # Supprime les espaces inutiles en début et fin de ligne
            
            # Vérifie si la ligne contient <bp>
            if "<bp>" in line:
                pos = line.find('/')  # Trouve la position du caractère '/'
                if pos != -1 and pos + 5 <= len(line):  # Vérifie que la position est valide
                    outfile.write(f"bp {line[pos+1:pos+5]}\n")  # Écrit le résultat dans le fichier de sortie
            
            # Vérifie si la ligne contient <m1>
            elif "<m1>" in line:
                pos = line.find('/')
                if pos != -1 and pos + 5 <= len(line):
                    outfile.write(f"m1 {line[pos+1:pos+5]}\n")
            
            # Vérifie si la ligne contient <m2>
            elif "<m2>" in line:
                pos = line.find('/')
                if pos != -1 and pos + 5 <= len(line):
                    outfile.write(f"m2 {line[pos+1:pos+5]}\n")
            
            # Vérifie si la ligne contient <sym>
            elif "<sym>" in line and i + 1 < len(lines):
                next_line = lines[i + 1].strip()  # Récupère la ligne suivante
                parts = next_line.split('|')  # Découpe la ligne en utilisant '|' comme séparateur
                
                if len(parts) > 7:  # Vérifie qu'il y a au moins 8 parties après découpage
                    symbol_part = parts[7].strip()  # Récupère la partie qui suit le septième '|'
                    symbol = symbol_part.split()[0] if symbol_part else ""  # Extrait le premier mot après l'espace
                    
                    pos = next_line.find('/')  # Trouve la position du '/'
                    if pos != -1 and pos + 5 <= len(next_line):
                        address = next_line[pos+1:pos+5]  # Extrait les 4 caractères après '/'
                        outfile.write(f"sym {symbol} = {address}\n")
            
            # Vérifie si la ligne contient "Equivalence"
            elif "Equivalence" in line:
                if len(line) > 90:  # Vérifie que la ligne est assez longue
                    equiv = line[90:].split()[0] if len(line[90:].split()) > 0 else ""  # Extrait la valeur de equiv
                    
                    equ_pos = line.find(" equ ")  # Trouve la position de " equ "
                    if equ_pos != -1:
                        address_part = line[equ_pos + 5:].strip()  # Extrait la partie après " equ "
                        address = address_part.split()[0] if address_part else ""  # Extrait la première valeur après " equ "
                        outfile.write(f"sym {equiv} = {address}\n")  # Écrit le résultat dans le fichier de sortie
            
            i += 1  # Passe à la ligne suivante

# Utilisation du programme
process_file("cw_Output.txt", "DebuggerAutorun.txt")
