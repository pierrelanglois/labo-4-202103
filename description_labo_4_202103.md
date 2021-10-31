-----------------------------------------------------------------------
<table>
<tr>
<td><img src="figures/Polytechnique_signature-RGB-gauche_FR.png" alt="Logo de Polytechnique Montréal"></td>
<td><h2>INF3500 - Conception et réalisation de systèmes numériques
<br><br>Automne 2021
<br><br>Laboratoire #4 : Conception de chemins des données
</h2></td>
</tr>
</table>

-----------------------------------------------------------------------

# Calculs cryptographiques sur FPGA : hachage SHA-1 et preuve de travail

------------------------------------------------------------------------

## Objectifs du laboratoire

À la fin de ce laboratoire, vous devrez être capable de :

- Concevoir et modéliser en VHDL un chemin des données qui réalise des fonctions arithmétiques et logiques complexes au niveau du transfert entre registres (_Register Transfer Level_ – RTL). (B5)
    - Instancier des registres, dont des compteurs
    - Implémenter les fonctions arithmétiques et logiques pour les valeurs des registres, correspondant à une spécification par micro-opérations ou par pseudocode
- Composer un banc d’essai pour stimuler un modèle VHDL d’un chemin des données. (B5)
    - Générer un signal d'horloge et un signal de réinitialisation
    - Générer et appliquer des stimuli à un circuit séquentiel
    - Comparer les sorties du circuit à des réponses attendues pré-calculées
    - Utiliser des énoncés `assert` ou des conditions pour vérifier le module
    - Générer un chronogramme résultant de l’exécution du banc d’essai, et l'utiliser pour déboguer le circuit, entre autres pour résoudre les problèmes de synchronisation
- Implémenter un chemin des données sur un FPGA
    - Effectuer la synthèse et l'implémentation du circuit
    - Extraire, analyser et interpréter des métriques de coût d'implémentation
    - Programmer le FPGA et vérifier le fonctionnement correct du circuit avec les interfaces de la planchette
    - Communiquer avec le circuit via l'interface série d'un ordinateur

Ce laboratoire s'appuie principalement sur le matériel suivant :
1. Les procédures utilisées et les habiletés développées dans les laboratoires #1, #2 et #3.
2. La matière des cours des semaines 4 (Modélisation et vérification de circuits séquentiels), 5 (Conception de chemins des données) et 6 (Conception et implémentation de fonctions arithmétiques sur FPGA).

### Préparatifs

- Créez un répertoire "inf3500\labo4\" dans lequel vous mettrez tous les fichiers de ce laboratoire.
- Importez tous les fichiers du laboratoire à partir de l'entrepôt Git et placez-les dans votre répertoire \labo4\
- Lancez Active-HD, créez un espace de travail (workspace) et créez un projet (design). Ajoutez-y tous les fichiers importés. Ou bien lancez et configurez votre environnement de travail préféré.

## Partie 0 : Introduction

Dans cet exercice de laboratoire, on considère le problème de l'implémentation de fonctions de hachage pour réaliser une preuve de travail.

### Les fonctions de hachage cryptographique

Les [fonctions de hachage cryptographique](https://fr.wikipedia.org/wiki/Fonction_de_hachage_cryptographique) (alias fonctions de hachage) sont fondamentales en cryptographie. Elles permettent entre autres :
- de vérifier l'intégrité de fichiers ou de messages;
- de vérifier des mots de passe de façon sécuritaire;
- d'identifier des fichiers ou des données;
- de dériver des clés cryptographiques;
- de générer des nombres pseudo-aléatoires;
- de démontrer une [preuve de travail](https://fr.wikipedia.org/wiki/Preuve_de_travail).

Une fonction de hachage calcule une empreinte (alias empreinte numérique, haché, hachage, valeur de hachage, _message digest_, _digest_, _hash_) correspondant à un message. Le message peut être par exemple un fichier ou une chaîne de caractères. Une fonction de hachage est une fonction à sens unique : il est difficile ou impossible de l'inverser, c'est à dire de trouver le message à partir de l'empreinte. Une bonne fonction de hachage a les caractéristiques suivantes :
- La fonction est déterministe : un message a une seule empreinte.
- Il est facile de calculer l'empreinte correspondant à un message.
- Il est infaisable (_computationnaly infeasible_) de générer un message correspondant à une empreinte.
- Il est infaisable (_computationnaly infeasible_) de trouver deux messages ayant la même empreinte.
- Deux messages similaires ont des empreintes très différentes - on ne peut pas modifier un message sans changer son empreinte.

La notion d'infaisabilité réfère à l'impossibilité de trouver une solution dans un temps raisonnable même avec une très grande puissance de calcul. Par exemple, pour une bonne fonction de hachage, la seule façon de trouver un message qui corresponde à une empreinte est de faire une recherche exhaustive avec des millions de processeurs pendant des milliards d'années.

Des fonctions de hachage bien connues incluent [MD5](https://fr.wikipedia.org/wiki/MD5), [SHA-1](https://fr.wikipedia.org/wiki/SHA-1) et [SHA-2](https://fr.wikipedia.org/wiki/SHA-2) . Dans le présent laboratoire, nous allons considérer l'algorithme SHA-1. La figure suivante illustre l'application d'une fonction de hachage cryptographique à différents messages en utilisant l'algorithme SHA-1. [Attention : dans cet exemple, les entrées sur plusieurs lignes incluent des caractères de retour de chariot - il faut les inclure pour obtenir les empreintes indiquées.]

![Exemples de l'application d'une fonction de hachage cryptographique à différents messages](figures/Cryptographic_Hash_Function.svg)  
[Source de l'image : _Jorge Stolfi based on Image:Hash_function.svg by Helix84 — Original work for Wikipedia, Domaine public, https://commons.wikimedia.org/w/index.php?curid=5290240_]

Plusieurs outils en ligne permettent de calculer des empreintes. Par exemple, la page de [Movable Type](https://www.movable-type.co.uk/scripts/sha1.html) inclut une boîte dans laquelle on peut entrer du texte et obtenir son empreinte pour l'algorithme SHA-1. Le code Javascript est inclus dans le bas de la page. Utilisez cette page ou une autre de votre choix et complétez les exercices suivants pour confirmer votre compréhension des principes de base des fonctions de hachage. Ces exercices ne sont pas notés dans le cadre de ce laboratoire.
- Vérifiez que l'empreinte SHA-1 du texte "abc" est bien a9993e364706816aba3e25717850c26c9cd0d89d.
- Obtenez l'empreinte SHA-1 de votre prénom. Notez la différence si vous utilisez une lettre majuscule ou non au début de votre prénom.
- Trouvez un prénom d'homme dont l'empreinte SHA-1 est 8ce4081e7eea6ace8332c7eb78415c57ec6ef2e3.
- Trouvez une chaîne de caractères dont l'empreinte SHA-1 commence par le chiffre 0.
- Trouvez une chaîne de caractères dont l'empreinte SHA-1 commence par les chiffres 00.

### Le concept de preuve de travail

En informatique, le concept de [preuve de travail](https://fr.wikipedia.org/wiki/Preuve_de_travail) (_proof of work_) réfère en général à une exigence imposée à un demandeur de service avant de lui fournir ce service. Par exemple, le demandeur doit trouver la solution à un problème mathématique qui nécessite un effort non trivial de calcul. Le concept de preuve de travail est au coeur des [cryptomonnaies](https://fr.wikipedia.org/wiki/Cryptomonnaie) comme Bitcoin et de certains systèmes pour lutter contre les pourriels comme [Hashcash](http://hashcash.org/).

Un exemple simple de problème pouvant être utilisé en guise de preuve de travail est le calcul de la racine carrée : il est facile de calculer x^2 mais beaucoup plus difficile de calculer sqrt(x), surtout si x est exprimé avec des milliers de chiffres. La plupart des systèmes de preuve de travail utilisent plutôt des fonctions de hachage avec une complexité réduite du problème. On peut par exemple demander de trouver un message de taille fixe répondant à certaines contraintes, dont le début de l'empreinte est égal à "0000". Un exemple montrant cette approche se trouve [dans la page Wikipédia sur les preuves de travail](https://fr.wikipedia.org/wiki/Preuve_de_travail#Exemple). Un exemple d'utilisation concrète pour filtrer des pourriels se trouve [dans la FAQ de la page de Hashcash](http://hashcash.org/faq/index.fr.php).

### Algorithme SHA-1

Dans ce laboratoire, nous allons utiliser [l’algorithme SHA-1](https://fr.wikipedia.org/wiki/SHA-1) pour effectuer une preuve de travail. L'algorithme est décrit en détail dans la norme [FIPS PUB 180-1, Secure Hash Standard, US Department of Commerce, 1995 April 17](https://nvlpubs.nist.gov/nistpubs/Legacy/FIPS/fipspub180-1.pdf) disponible à partir de la page du [National Institue of Standards and Technology](https://csrc.nist.gov/publications/detail/fips/180/1/archive/1995-04-17). Il consiste en deux parties : le prétraitement du message et l'application de 80 étapes de calcul.

#### 1. Le prétraitement du message et sa décomposition en blocs.

Avant de calculer l'empreinte d'un message, il faut le décomposer et l'encoder dans des blocs de 16 mots de 32 bits. Pour ce laboratoire, nous allons nous limiter à des messages composés d'au maximum 55 caractères ASCII, qui entrent alors dans un seul bloc de 16 mots de 32 bits.

Quand le message entre dans un seul bloc, ce bloc est composé de :
- n = 0 à 55 octets d'information, encodés en ASCII (par exemple "Bonjour! 1234" contient n = 13 caractères);
- l'octet 0x80, qui suit immédiatement les octets d'information;
- (55 – n) octets NULL (0x00) pour que la taille du bloc soit exactement de 512 bits;
- 8 octets (64 bits) pour encoder la taille du message en bits (une valeur entre 0 et 55 x 8 = 440).

Les blocs ont donc toujours une taille de n + 1 + (55 - n) + 8 = 64 octets de 32 bits = 512 bits. Le fichier [SHA_1_utilitaires_pkg.vhd](sources/SHA_1_utilitaires_pkg.vhd) contient plusieurs exemples de messages encodés sur des blocs. 

#### 2. L'application de 80 étapes (alias rondes) d'opérations simples à chacun des blocs du message.

Le calcul de l'empreinte s'effectue en 80 étapes de calcul à l'aide d'un chemin des données qui inclut  l'utilisation de constantes, le ou-exclusif, le décalage et l'addition modulo-32. L'addition modulo-32 est une addition sur 32 bits dans laquelle on laisse tomber la retenue finale. Le schéma suivant montre le chemin des données de l’algorithme SHA-1.

![Une étape de l'algorithme SHA-1](figures/SHA-1-90deg.svg)

[Source de l’image et licence d'utilisation : Utilisateur Matt Crypto, CC BY-SA 2.5, https://commons.wikimedia.org/w/index.php?curid=1446602]

On observe les composants suivants dans le schéma :
- Cinq registres de calcul de 32 bits A, B, C, D, E, à la fois comme source (à gauche) et comme destination (à droite).
- Quatre additionneurs modulo-32, indiqués par des boîtes en rouge avec une croix à l'intérieur.
- La fonction combinatoire `F` montrée par une boîte verte.
- 16 registres de 32 bits `W0` à `W15` pour entreposer le bloc au départ puis calculer son expansion (_message schedule_), montrés par le symbole `Wt` dans le schéma.
- Une mémoire ROM `K` qui prend entrée le numéro `t` de l'étape et qui retourne une constante `Kt`.
- Deux blocs de rotation circulaire montrés par des boîtes jaunes. Le symbole `<<< n` signifie "rotation circulaire des bits vers la gauche de n positions".

Le chemin des données inclut aussi les registres suivants, qui ne sont pas montrés dans le schéma :
- 1 registre `t` pour compter les étapes : les calculs varient en fonction de l'étape t
- 1 registre `fini` indiquer quand on a fini (c'est un port de sortie)
- 1 registre `empreinte` pour entreposer l'empreinte finale (c'est un port de sortie)

Après 80 étapes, l'empreinte finale est formée par la concaténation des registres A, B, C, D et E, auxquels on ajoute d'abord des constantes H0_init, H1_init, H2_init, H3_init et H4_init, respectivement, avec des additions modulo-32.

Les détails des opérations des 80 étapes et les valeurs d’initialisation des registres sont données dans le pseudocode montré plus loin.


## Partie 1 : Modéliser et simuler l'algorithme SHA-1

Modifiez le fichier [SHA_1.vhd](sources/SHA_1.vhd) pour modéliser les micro-opérations du pseudo-code suivant.

    si reset == '1' {
        t ← 80
        fini ← '1'
    } sinon, à chaque coup d'horloge {
        si t == 80 {
            fini ← '1'
            empreinte ← (A + H0_init) & (B + H1_init) & (C + H2_init) & (D + H3_init) & (E + H4_init)
            si charge_et_go == '1' {
                A ← H0_init
                B ← H1_init
                C ← H2_init
                D ← H3_init
                E ← H4_init
                W ← bloc
                t ← 0
                fini ← '0'
            }
        } sinon {
            si t >= 15 {
                W((t + 1) mod 16) ← rotate_left(W((t + 14) mod 16) xor W((t + 9) mod 16) xor W((t + 3) mod 16) xor W((t + 1) mod 16), 1)
            }
            -- mise à jour de A, B, C, D, E selon le diagramme
            -- attention, W est un tampon circulaire de 16 valeurs, dans l'équation pour A il faut prendre W(t mod 16)
            A ← rotate_left(A, 5) + f(B, C, D, t) + E + W(t mod 16) + k(t);
            B ← A;
            C ← rotate_left(B, 30);
            D ← C;
            E ← D;
            
            t ← t + 1;
        }
    }

Le fichier [SHA_1_utilitaires_pkg.vhd](sources/SHA_1_utilitaires_pkg.vhd) inclut entre autres les définitions de types, les fonctions f() et k() et les constantes Hx_init.

Vérifiez le fonctionnement correct de votre module avec le banc d'essai [SHA_1_TB.vhd](sources/SHA_1_TB.vhd). Pour déboguer, vous pouvez utiliser l'exemple de l'appendice A du document [FIPS PUB 180-1, Secure Hash Standard, US Department of Commerce, 1995 April 17](https://nvlpubs.nist.gov/nistpubs/Legacy/FIPS/fipspub180-1.pdf) qui montre la valeur des registres A, B, C, D, E après chacune des 80 étapes de traitement.

À remettre pour la partie 1 :
- Votre fichier [SHA_1.vhd](sources/SHA_1.vhd) modifié. Ne modifiez pas le nom du fichier, le nom de l'entité, la liste et le nom des ports, ni le nom de l'architecture.
- Votre fichier [SHA_1_TB.vhd](sources/SHA_1_TB.vhd) si vous le modifiez pour ajouter des tests.
- Des commentaires dans le fichier [rapport.md](rapport.md) qui expliquent brièvement vos modifications de la partie 1.

## Partie 2 : Preuve de travail par recherche de collisions partielles

Votre tâche consiste à concevoir un module qui ajoute des caractères à un message de base afin de trouver des collisions partielles dans l'empreinte résultante. Votre module doit prendre un message de base donné, par exemple "Bonjour, monde !", et lui ajouter une chaîne candidate composée de N caractères hexadécimaux. Par exemple, pour N = 8, on pourrait avoir comme chaîne candidate "a0b1c2d3", ce qui donne la chaîne combinée "Bonjour, monde !a0b1c2d3". Votre module doit composer un bloc avec ce message. Vous pouvez utiliser la fonction `compose_bloc(string)`, en faisant par exemple `monbloc <= compose_bloc(message_de_base & chaine_candidate)`. Votre module doit soumettre le bloc au module SHA-1 et attendre que l'empreinte soit calculée.

Votre module doit ensuite vérifier s'il y a une collision partielle pour l'empreinte, c’est-à-dire si elle débute par une suite de bits que vous spécifiez, par exemple x"00" pour 8 bits à 0. S'il n'y a pas de collision, votre module doit former une nouvelle chaîne, par exemple "Bonjour, monde !a0b1c2d4" et recommencer jusqu'à ce qu'une collision soit trouvée. Votre module doit alors s'arrêter. Pour simplifier les choses, le message de base (p. ex. "Bonjour, monde !") et la collision partielle recherchée (p. ex. "00") dans l'empreinte doivent être des constantes spécifiées dans des énoncés `generic` de l'entité.

Modifiez le fichier [SHA_1_cherche_collisions.vhd](sources/SHA_1_cherche_collisions.vhd) pour décrire votre module. Un banc d'essai très simple SHA_1_cherche_collisions_tb est donné dans le même fichier. Il n'est probablement pas nécessaire de modifier ce banc d'essai, mais indiquez-le si vous le modifiez.

Simulez le fonctionnement de votre circuit à l'aide du banc d'essai. Faites-lui chercher des collisions avec 1, 2, 3 ou plus de zéros en en-tête de l'empreinte, ou d'autres caractères.

À remettre :
- Votre fichier modifié [SHA_1_cherche_collisions.vhd](sources/SHA_1_cherche_collisions.vhd). Ne modifiez pas le nom du fichier, le nom de l'entité, la liste et le nom des ports, la liste et le nom des `generic`, ni le nom de l'architecture.
- Des commentaires dans le fichier [rapport.md](rapport.md) qui expliquent brièvement vos modifications de la partie 2.

## Partie 3 : Implémentation sur la planchette

Implémentez votre module SHA_1_cherche_collisions sur la planchette et faites-lui chercher des collisions ! Essayez tout d'abord avec des problèmes faciles et de courtes collisions, puis augmentez progressivement la difficulté.

Utilisez le fichier [top_labo_4.vhd](sources/top_labo_4.vhd) modifiez-le si nécessaire.

Utilisez le fichier de commandes [labo_4_synth_impl.tcl](synthese-implementation/labo_4_synth_impl.tcl). Commentez et décommentez les lignes appropriées du fichiers selon la planchette que vous utilisez.

## Partie 4: Bonus

**Mise en garde**. *Compléter correctement les parties 1, 2 et 3 peut donner une note de 17 / 20 (85%), ce qui peut normalement être interprété comme un A. La partie bonus demande du travail supplémentaire qui sort normalement des attentes du cours. Il n'est pas nécessaire de la compléter pour réussir le cours ni pour obtenir une bonne note. Il n'est pas recommandé de s'y attaquer si vous éprouvez des difficultés dans un autre cours. La partie bonus propose un défi supplémentaire pour les personnes qui souhaitent s'investir davantage dans le cours INF3500 en toute connaissance de cause.*

### FPGA vs votre ordinateur
Considérez le script Python du fichier [cp.py](scripts/cp.py).

Exécutez ce script et comparez les temps de recherche entre votre implémentation sur FPGA et le script qui tourne sur votre ordinateur. Effectuez des expériences pour différentes tailles de collisions. Visez des cas qui prennent plusieurs heures, comme une nuit complète. Vous pouvez expérimenter avec des tailles de chaîne candidate supérieures à 16 caractères.

Vous pouvez modifier le script Python pour en accélérer l'exécution, entre autres en simplifiant la création de la chaîne candidate. Par exemple, on n'a pas besoin que ce soit une chaîne aléatoire, ce qui pourrait permettre d'éliminer un appel de fonction dans la boucle de recherche.

Vous pouvez faire tourner le script Python sur un serveur de calcul, si vous y avez accès.

Si vous réussissez à battre le FPGA, modifiez votre module pour en accélérer l'exécution. Par exemple, vous pouvez implémenter 2, 4, 8, ou plus modules en parallèles qui explorent chacun une partie de l'espace de recherche. Les possibilités ne sont limitées que par le temps que vous décidez d'allouer à ce problème. Lire la mise en garde à nouveau SVP.

Documentez vos expériences et vos résultats dans votre [rapport.md](rapport.md). Remettez votre script  [cp.py](scripts/cp.py) modifié et minutieusement commenté.


### Super Bonus : Craquez SHA-1
Proposez une façon de craquer SHA-1, c'est à dire de trouver 'rapidement' un message qui donne une collision partielle arbitrairement longue. Compléter ce bonus ne donne aucun point supplémentaire, mais apporte la gloire, la fortune (à partager avec les chargés de labo et le prof de INF3500) et une visite par des hommes en noir de la NSA (à assumer conjointement par les partenaires de l'équipe).

## Remise

La remise se fait directement sur votre entrepôt Git. Poussez régulièrement vos modifications, incluant pour la version finale de vos fichiers avant l'heure et la date limite de la remise. Consultez l'ébauche du fichier [rapport.md](rapport.md) pour la liste des fichiers à remettre.

**Directives spéciales :**
- Ne modifiez pas les noms des fichiers, les noms des entités, les listes des ports, les listes des `generics` ni les noms des architectures.
- Remettez du code de très bonne qualité, lisible et bien aligné, bien commenté. Indiquez clairement la source de tout code que vous réutilisez ou duquel vous vous êtes inspiré/e.
- Modifiez et complétez le fichier [rapport.md](rapport.md) pour donner des détails supplémentaires sur votre code. Spécifiez quelle carte vous utilisez.

## Barème de correction

Le barème de correction est progressif. Il est relativement facile d'obtenir une note de passage (> 10) au laboratoire et il faut mettre du travail pour obtenir l'équivalent d'un A (17/20). Obtenir une note plus élevée (jusqu'à 20/20) nécessite plus de travail que ce qui est normalement demandé dans le cadre du cours et plus que les 9 heures que vous devez normalement passer par semaine sur ce cours.

Critères | Points
--------- | ------
Partie 1 : modélisation de l'algorithme SHA-1 | 6
Partie 2 : recherche de collisions partielles | 6
Partie 3 : implémentation sur la planchette| 3
Qualité, lisibilité et élégance du code : alignement, choix des identificateurs, qualité et pertinence des commentaires, respect des consignes de remise incluant les noms des fichiers, orthographe, etc. | 2
**Pleine réussite du labo** | **17**
Partie 4 : Bonus | 3
Partie 4 : Super Bonus | ∞ + $
**Maximum possible sur 20 points** | **20**

## Références pour creuser plus loin

Les liens suivants ont été vérifiés en septembre 2021.

- Aldec Active-HDL Manual : accessible en faisant F1 dans l'application, et accessible [à partir du site de Aldec](https://www.aldec.com/en/support/resources/documentation/manuals/).
- Tous les manuels de Xilinx :  <https://www.xilinx.com/products/design-tools/vivado/vivado-ml.html#documentation>
- Vivado Design Suite Tcl Command Reference Guide : <https://www.xilinx.com/content/dam/xilinx/support/documentation/sw_manuals/xilinx2021_1/ug835-vivado-tcl-commands.pdf>
- Vivado Design Suite User Guide - Design Flows Overview : <https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_2/ug892-vivado-design-flows-overview.pdf>
- Vivado Design Suite User Guide - Synthesis : <https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_2/ug901-vivado-synthesis.pdf>
- Vivado Design Suite User Guide - Implementation : <https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_2/ug904-vivado-implementation.pdf>