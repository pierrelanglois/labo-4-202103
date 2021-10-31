#
# cp.py
# recherche de collisions partielles (cp)
# une collision est définie par un certain nombre de caractères '0' au début de l'empreinte
# algorithme SHA-1
#
# v. 1.1 2021-10-30 Pierre Langlois, inspiré de sources très variées, en particulier :
#   https://www.w3schools.com/python/
#   https://stackoverflow.com/questions/2257441/random-string-generation-with-upper-case-letters-and-digits
#   etc. etc.

import hashlib
import random
import string
import datetime

def chaine_aleatoire_hex(n_car):
    caracteres = string.hexdigits
    chaine = ''.join(random.choice(caracteres) for i in range(n_car))
    return chaine


message = "Bonjour, monde !"

print("\n-----------------\npreuve de travail par recherche de collisions (suite de zéros en tête de l'empreinte) pour l'algorithme SHA-1")
print('pour la chaine : "' + message + '"')
print("-----------------\n")

# effectuer la recherche pour plusieurs longueurs de collisions
for longueur in range(1, 7):
    
    # initialisation de la recherche
    fini = False
    essai = 0
    dt1 = datetime.datetime.now()
    print("recherche d'une collision de longueur " + str(longueur) + ", moment de début = " + str(dt1))
    
    # lancer la recherche
    while (not fini) :
        
        # où est-on rendu ?
        essai = essai + 1
        if essai % 100000 == 0 :
            print("recherche en cours, essai #" + str(essai))
        
        # construire la chaîne combinée du message et de la chaîne candidate
        chaine_candidate = chaine_aleatoire_hex(16)
        chaine_combinee = message + chaine_candidate
        
        # calculer l'empreinte
        empreinte = hashlib.sha1(bytes(chaine_combinee, 'ASCII')).hexdigest()
        
        # vérifier si on a une collision, et si oui afficher les informations pertinentes
        if empreinte[0:longueur] == '0' * longueur:
            fini = True
            dt2 = datetime.datetime.now()
            print(dt2 - dt1)
            print("Succès avec l'essai #" + str(essai) + " après un temps de " + str(dt2 - dt1))
            print("La chaîne combinée est : " + chaine_combinee)
            print("L'empreinte est : " + empreinte)
            print("Il est : " + str(dt2))
            print('-----------------')
 

