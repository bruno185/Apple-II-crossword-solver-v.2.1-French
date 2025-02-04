def process_file(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as infile, open(output_file, 'w', encoding='utf-8') as outfile:
        lines = infile.readlines()
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            if "<bp>" in line:
                pos = line.find('/')
                if pos != -1 and pos + 5 <= len(line):
                    outfile.write(f"bp {line[pos+1:pos+5]}\n")
            
            elif "<m1>" in line:
                pos = line.find('/')
                if pos != -1 and pos + 5 <= len(line):
                    outfile.write(f"m1 {line[pos+1:pos+5]}\n")
            
            elif "<m2>" in line:
                pos = line.find('/')
                if pos != -1 and pos + 5 <= len(line):
                    outfile.write(f"m2 {line[pos+1:pos+5]}\n")
            
            elif "<sym>" in line and i + 1 < len(lines):
                next_line = lines[i + 1].strip()
                parts = next_line.split('|')
                if len(parts) > 7:
                    symbol_part = parts[7].strip()
                    symbol = symbol_part.split()[0] if symbol_part else ""
                    
                    pos = next_line.find('/')
                    if pos != -1 and pos + 5 <= len(next_line):
                        address = next_line[pos+1:pos+5]
                        outfile.write(f"sym {symbol} = {address}\n")
            
            elif "Equivalence" in line:
                if len(line) > 93:
                    equiv = line[90:].split()[0] if len(line[93:].split()) > 0 else ""
                    
                    equ_pos = line.find(" equ ")
                    if equ_pos != -1:
                        address_part = line[equ_pos + 5:].strip()
                        address = address_part.split()[0] if address_part else ""
                        outfile.write(f"sym {equiv} = {address}\n")
            
            i += 1

# Utilisation
process_file("cw_Output.txt", "DebuggerAutorun.txt")
