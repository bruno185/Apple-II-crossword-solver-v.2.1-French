# Apple II Crossword Solver (v2.1.1)


Voici un programme pour Apple II (e, c, GS) pour aider les cruciverbistes à trouver des mots.
La difficulté était de retrouver RAPIDEMENT les mots possibles en fonction des lettres connues, parmi un vocabulaire de plus de 407 000 mots !
Exemple : A en première position, lettre inconnue en position 2, et A en dernière position
=> ADA, AGA, ANA, ARA, ASA, AXA.

Bien sûr, les données (mots et indexes) ne tiennent pas sur une disquette, mais sur un disque dur physique ou virtuel, et occupent environ 20 Mo.

Dans les versions précédentes, j'avais écrit un programme en Delphi pour générer les index à partir de la liste de mots.
Dans cette version, j'ai demandé à ChatGPT d'écrire ce programme en python !! (voir plus bas).

## Utilisation
Cette archive contient une image disque ProDOS (cw.po) à utiliser avec votre émulateur Apple II favori ou votre Apple II.
* Démarrez votre Apple II avec la disquette "cw.po". Pour Applewin, l'image disque doit être dans le "Hard disk drive".
* Lancez le programme avec "brun cw", ou « -cw » (le programme STARTUP devrait le faire pour vous).
* Tapez des lettres majuscules, ou ? pour les lettres inconnues. Entrez pour valider. Escape ou ctrl-c pour quitter.

## Performances
Sur un Apple II ou un émulateur réglé à la vitesse normale, le traitement est maintenant assez rapide, la recherche s'effectue en une seconde environ.

## Techniques
* La liste de mots  
Le fichier texte de la liste de mots est obtenu en ligne, c'est la liste officielle du Scrabble (ODS) version 9, devenue la référence au 1er janvier 2024.
Dans les précédentes versions de mon "Apple II Crossword Solver", j'avais utilisé la version 8 (ODS8, 2020). 
Ces fichiers sont dans le répertoire "python/Officiel du Scrabble".
Dans la version 9, de nombreux mots ont été ajoutés par rapport à la version 8, voir le fichier "mots ajoutés en 2024.txt".
Plus étonnant, des mots ont été retirés par l'éditeur du jeu de Scrabble, voir le fichier "mots retirés en 2024.txt".
J'ai réintégré ces mots dans l'ODS9, l'ensemble étant enregistré dans le fichier "ods9 (2024)++.txt".
Les mots de l'ODS9 sont répartis dans les répertoire L2 à LF, en fonction de leur longueur (mots de 2 lettres à mots de 15 lettres). Chacun de ces répertoires contient un fichier "WORDS" comprenant ce sous-ensemble de mots.
La recherche est donc réduite aux seuls mots dont la longueur est égale au pattern de recherche tapé par l'utilisateur, ce qui l'accélère sensiblement.

* Les index  
Il y a un index par lettre et par position. Exemple : 
Fichier index A1 pour les mots avec A en position 1, B2 pour les mots avec B en position 2, etc. 
Les index sont des bitmaps. La position des bit à 1 indique la position du mot dans le fichier "WORDS". 
Exemple : dans l'index F6, si le 9eme bit est à 1 (= bit 1 de l'octet 2), cela signifie que le 9eme mot du fichier "WORDS" contient un F en 6eme position. 
Il est facile en assembleur de combiner ces bitmaps par l'opération logique AND, pour obtenir la position des mots recherchés. Exemple avec le pattern : V??O :
Le programme ira dans le répertoire L4, puisque les mots recherchés ont 4 lettres, il chargera l'index V1 (V en position 1) et l'index O4 (O en position 4). Il fera un AND entre ces deux bitmaps. Enfin il parcourra le bitmap résultant, et  chaque bit à 1 lui donnera la position d'un mot correspondant au pattern dans la liste de mots "WORDS du répertoire L4 (dans ce cas : VELO, VETO,etc.)

* La génération des index  
Les index sont générés par un programme écrit en python.
Le programme python ("python/make_index.py") a été écrit par ChatGPT, à partir de spécifications présentes dans le fichier "python/cahier des charges chatgpt.txt"
Ce fichier contient deux parties. 
La première partie fait générer par ChatGPT un programme pas tout à fait correct. 
Il faut indiquer la seconde partie à ChatGPT pour qui fasse les corrections nécessaires. 
Le programme est alors correct. Les fichiers générés sont identiques à ceux que produit la le programme que j'avais écrit en Delphi dans les précédentes versions.
Attention : d'une fois sur l'autre, le programme produit par ChatGPT n'est pas exactement le même, avec parfois des régressions et même des bugs bloquants.
Jusqu'à présent, il n'a pas été possible de faire générer le bon programme en une passe, certaines consignes n'étant pas respectées par ChatGPT.

## Nouveautés de la version 2.1 French
* Vocabulaire enrichi : Officiel du Scrabble v9 (2024)
* Correction de bugs mineurs
* Améioration des performances du code assembleur 6502
* Accepte les lettres minuscules
* Génération des index par un programme python, lui-même généré par ChatGPT
* Très grande efficacité de ce programme
* Automatisation de la copie des fichiers index dans l'image disque par Cadius (cf. "do_index.bat")
* Intégration de mon système de balisage du code source Merlin, pour bénéficier des symboles dans le débuggeur d'Applewin (cf. SetBreaks.cpp)

## Les améliorations de la version 2.1.1 French
* Amélioration significative des performances en ne traitant que l'espace mémoire nécessaire, et non l'ensemble des espaces de travail ($2000 à $3FFF et $4000 à $5FFF)

## Credits
L'algorithme est celui utilisé dans le logiciel français « Easy Puss », pour ceux qui se souviennent de ce logiciel de base de données pour Apple II, publié dans les années 80 par l'éditeur de "4e Dimension". Il est appliqué aux lettres et à leurs positions dans le cas présent.

## Conditions requises pour la compilation et l'exécution

Voici la configuration :

* Visual Studio Code avec 2 extensions :

-> [Merlin32 : 6502 code hightliting](marketplace.visualstudio.com/items?itemName=olivier-guinart.merlin32)

-> [Code-runner :  running batch file with right-clic.](marketplace.visualstudio.com/items?itemName=formulahendry.code-runner)

* [Merlin32 cross compiler](brutaldeluxe.fr/products/crossdevtools/merlin)

* [Applewin : Apple IIe emulator](github.com/AppleWin/AppleWin)

* [Applecommander ; disk image utility](applecommander.sourceforge.net)

* [Cadius ; disk image utility](www.brutaldeluxe.fr/products/crossdevtools/cadius/index.html)

* [Ciderpress ; disk image utility](a2ciderpress.com)

Note :

Le fichier "do_asm.bat" compile les fichiers source (*.s) assembleur avec Merlin32, et dépose le fichier binaire 6502 ainsi créé sur l'image disque "cw.po". Si vous souhaitez compiler vous-même, vous devrez modifier le fichier "do_asm.bat" pour adapter les chemins vers des répertoires Merlin32, Applewin et Applecommander.

Le fichier "do_index.bat" lance le programme python qui génère les indexs à partir de la liste de mots. Les fichiers index sont ensuite copiés sur l'image disque "cw.po".