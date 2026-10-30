# Compte rendu — TD Stockage de matrices en C

Membres:YOUSSEF Daniel, SAMY Eshina - TD 1 STI 3A

## 1. En-tête
TD 1 - STI 3A
Date de Remise: 30/10/26

Membres du groupe et identifiants GitHub.
Eshina Samy : @samyeshina
Daniel Youssef : @Daniel31-dive


## 2. Introduction
### But du TD
Ce TD vise à concevoir une petite bibliothèque C permettant de créer, sauvegarder, relire, afficher et calculer la somme et le produit des matrices d’entiers. A travers la complétion de plusieurs modules et d’un programme de démonstration qui nous ont été fournis, nous allons apprendre à distinguer un fichier d’interface (fichier.h) de son implémentation (fichier.c) en compilant séparément chaque modules puis en les assemblant par édition de liens. En se faisant, nous établirons également des règles de propriété de mémoire que nous devons respecter.

Ce projet nous a surtout permis d'adopter de bonnes pratiques de développement en testant notre code pas à pas à chaque étape. En programmation C, ce qui surtout important c’est une gestion rigoureuse de la mémoire. Des règles précises de propriété de la mémoire ont été établies et appliquées ici pour garantir l'absence totale de fuites, même lors d'un échec d'allocation partiel.

### Etat du Projet à la remise
L'ensemble des exercices 1 à 4 est validé et fonctionnel. Les trois programmes de test obtiennent un score de 100 %, et l'exécutable final  s’exécute sans aucun avertissement de compilation ni aucune fuite mémoire sous Valgrind (validé également avec leaks sous macOS).



## 3. Conception
### Schéma des modules : les 4 modules et le programme principal, avec qui appelle qui
main.c / demo_main —> matrice_io, matrice_calcul, matrice_alloc
matrice_alloc —> matrice
matrice_io & matrice_calcul —> matrice_alloc, matrice

### Graphe des inclusions : quel fichier inclut quel .h 
main.c —> "matrice.h"
main.c —>"matrice_alloc.h"  ──> "matrice.h"
main.c —>"matrice_io.h"  ──> "matrice.h", <stdio.h>
main.c —>"matrice_calcul.h" ──> "matrice.h"

matrice_io.c  ──> "matrice_io.h", "matrice_alloc.h", <stdio.h>, <stdlib.h>, <errno.h>
matrice_calcul.c ──> "matrice_calcul.h", "matrice_alloc.h", <limits.h>
matrice_alloc.c  ──> "matrice_alloc.h", <stdlib.h>
matrice.c ──> "matrice.h", <stddef.h>

### Pourquoi le garde #ifndef est nécessaire?
main.c inclut à la fois matrice.h, matrice_alloc.h, matrice_io.h et matrice_calcul.h. Sans la garde d'inclusion (#ifndef MATRICE_H / #define MATRICE_H / #endif), le préprocesseur recopiera la définition du type struct matrice et de la structure Matrice quatre fois consécutives dans main.c, ce qui provoquera une erreur de compilation pour redéfinition de type.

### Règles de propriété de la mémoire 
R1 : Cela permet de s'assurer que toute matrice est initialisée et ne contient pas une valeur indéterminée.

R2 : Cela permet de transférer la responsabilité de libérer la mémoire à la fonction qui appellera la matrice après sa création.

R3 : Cela permet d'éviter des fuites de mémoire car si une allocation échoue la matrice est automatiquement vider.

R4 : const garantit que la donnée source est inchangée. Cela permet d'utiliser la même matrice d'entrée dans plusieurs calculs sans risque qu'elle ne soit changée ou libérée.

R5 : Si res pointait déjà vers une matrice allouée, réaffecter le pointeur détruirait l'adresse sans libérer la mémoire. De plus, interdire mat_additionner évite d'écraser les valeurs de a pendant que la boucle de calcul les lit encore.

R6 : Cela protège notre programme contre les erreurs car cela permet de faire plusieurs mat_detruire sans erreurs.

R7 : Cela permet à ces fonctions d'être utilisées aussi bien sur des fichiers que sur la sortie standard ou pour lire ou écrire plusieurs matrices consécutives dans le même flux.

Qui alloue ? Seules les fonctions génératrices de matrices (mat_allouer, mat_lire, mat_additionner, mat_multiplier) allouent de la mémoire dynamique sur le tas.
 
Qui utilise ? Les fonctions de traitement (mat_ecrire, mat_afficher) et les fonctions de calcul reçoivent les matrices sous forme de pointeurs constants (const Matrice *). Elles lisent les données sans jamais modifier la structure ni tenter de libérer la mémoire.

Qui libère ? En cas de succès (MAT_OK),la fonction transfère la propriété de la mémoire à l'appelant qui devra 'appeler mat_detruire quand il n'en a plus besoin. En cas d'échec, la fonction elle-même détruira tout ce qu'elle a partiellement alloué avant de quitter.

Que vaut une matrice après un échec? Elle vaut toujours MATRICE_VIDE 

### Justification des choix 
Utilisation de static : Le mot-clé static rend les fonctions internes invisibles pour les autres fichiers. Cela évite les conflits de noms lors de l'édition de liens et masque le code propre à chaque module.
Gestion de l'échec partiel d'allocation : Dans mat_allouer, si une allocation échoue au milieu du processus, la fonction libère les lignes déjà créées et le tableau de pointeurs principal. Cela évite les fuites de mémoire et renvoie proprement MAT_ERR_ALLOCATION.
Détection des dépassements de capacité (overflow) : Les calculs sont effectués en long long (64 bits) puis comparés à INT_MIN et INT_MAX avant stockage. Cela permet de bloquer les dépassements d'entiers signés avant qu'ils ne provoquent un comportement indéfini.



## 4. Réalisation
### Exercice 1 

samyeshina@Samys-MBP td_matrices % ./test_ex1
=== Exercice 1 : matrice.c ===
[OK]    (1.a) message pour MAT_ERR_DIMENSIONS
[OK]    (1.a) message pour MAT_ERR_DEPASSEMENT
[OK]    (1.b) une matrice 1 x 2 est valide
[OK]    (1.b) NULL n'est pas valide
[OK]    (1.b) MATRICE_VIDE n'est pas valide
[OK]    (1.b) une matrice de 0 ligne n'est pas valide
=== Exercice 1 : matrice_alloc.c ===
[OK]    (1.c) mat_allouer refuse 0 ligne
[OK]    (1.c) mat_allouer refuse -2 colonnes
[OK]    (1.c) mat_allouer refuse une dimension > MAT_DIM_MAX
[OK]    (1.e) mat_allouer(&m, 3, 4) renvoie MAT_OK
[OK]    (1.e) m a 3 lignes et 4 colonnes
[OK]    (1.d) tous les coefficients valent 0
[OK]    (1.f) apres mat_detruire, m est vide
[OK]    (1.f) un second mat_detruire est sans danger
[OK]    (1.f) mat_detruire(NULL) ne plante pas
=== Exercice 1 : echecs d'allocation simules ===
[OK]    (1.d) chaque echec renvoie MAT_ERR_ALLOCATION et laisse *res vide
Bilan : 16 / 16 verifications reussies.
Pensez a verifier l'absence de fuite : valgrind --leak-check=full ./test_ex1


#### Q3.1 Pourquoi mat_detruire prend-elle un Matrice * et non un Matrice ? Que se passerait-il,pour l’appelant, avec un passage par valeur ?

Si on avait fait un simple passage par valeur (matrice), la fonction n’aurait reçu qu’une copie locale de la structure qui serait détruite à la sortie de notre fonction. La variable initiale serait donc inchangée. De plus, lorsque la fonction va exécuter des free (), la mémoire sera libérée mais la variable initiale possède toujours un pointeur coef qui pointe vers son ancienne adresse mémoire qui a été libérée. Cela crée une erreur.

Si on passe Matrice au lieu de Matrice*, lors de nos tests, les blocs mémoire seront libérés, mais la matrice de l'appelant restera avec un pointeur coef != NULL. Un second appel consécutif à mat_detruire ne pourra pas détecter que la matrice était détruite et va provoquer un plantage immédiat (double free).


#### Q3.2 Combien d’appels à calloc et à free faut-il pour une matrice n × p ? Si la k-ième allocation échoue, combien de libérations mat_allouer doit-elle effectuer ?

Pour une matrice n × p : 1 + n appels à calloc (le tableau de pointeurs, puis une ligne par i) et 1 + n appels à free. Si la k-ième allocation échoue, mat_allouer fait k − 1 libérations : pour k = 1 (le tableau coef lui-même) il n'y a rien à libérer ; pour k ≥ 2 elle libère les k − 2 lignes déjà obtenues plus le tableau coef.

#### Q3.3 Appeler deux fois free sur la même adresse est un comportement indéfini. Pourquoi appeler deux fois mat_detruire sur la même matrice est-il sans danger ? Est-ce encore vrai si l’on a fait une copie Matrice b = a; puis appelé mat_detruire(&a) et mat_detruire(&b) ?

Après le premier appel, la matrice vaut MATRICE_VIDE : ‘coef == NULL’, donc le second appel ne fait rien (R6). Ceci n’est plus le cas avec une copie, ‘b.coef’ qui contient la même adresse. mat_detruire libère la mémoire et remet seulement ‘a’ à vide. ‘b.coef’ pointe toujours vers la zone libérée, donc mat_detruire effectue une double libération (comportement indéfini).

Nous avons essayé d'appeler deux fois mat_detruire(&a) à la suite, puis d'exécuter mat_detruire(&a) suivi de mat_detruire(&b). Dans le premier cas, nous avons obtenu un score de 16/16 sans crash. Dans le second cas,nous avons eu une erreur.


#### Q3.4 Pourquoi mat_allouer commence-t-elle par l’affectation *res=MATRICE_VIDE, avant même de vérifier les dimensions ?

Pour que toutes les sorties anticipées (argument invalide, échec d'allocation) laissent *res dans un état défini et sûr (R3). Sans cela, *res pourrait contenir une valeur indéterminée (variable non initialisée) ou l'ancienne matrice de l'appelant.

### Exercice 2
samyeshina@Samys-MacBook-Pro td_matrices % ./test_ex2
=== Exercice 2 : affichage (verification visuelle) ===
M (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
(2.a) Vous devez voir ci-dessus 4 lignes : 1 2 3 / 4 5 6 / 7 8 9 / 10 11 12
=== Exercice 2 : ecriture ===
[OK]    ouverture de test_ex2_sortie.txt en ecriture
[OK]    (2.b) mat_ecrire renvoie MAT_OK
[OK]    (2.b) le fichier contient exactement le format attendu
[OK]    (2.b) mat_ecrire refuse une matrice vide
=== Exercice 2 : relecture ===
[OK]    (2.f) mat_lire relit le fichier : MAT_OK
[OK]    (2.e) la matrice relue est identique
[OK]    (2.e) espaces et sauts de ligne en trop sont toleres
=== Exercice 2 : fichiers incorrects ===
[OK]    (2.c) fichier vide
[OK]    (2.c) dimension nulle
[OK]    (2.c) dimension negative
[OK]    (2.e) coefficient manquant
[OK]    (2.e) donnee non numerique
[OK]    (2.e) entier trop grand pour un int
=== Exercice 2 : echec d'allocation simule ===
[OK]    (2.d) mat_lire renvoie MAT_ERR_ALLOCATION proprement
Bilan : 14 / 14 verifications reussies.
Pensez a verifier l'absence de fuite : valgrind --leak-check=full ./test_ex2


#### Q4.1 Pourquoi mat_lire remplit-elle d’abord une matrice locale avant de l’affecter à *res ?

mat_lire respecte la R3 car elle utilise la variable locale tmp . Si la lecture s'interrompt brutalement au milieu de la matrice, la fonction appelle mat_detruire(&tmp) avant d'abandonner.  *res n'est donc jamais pollué par des données partielles et conserve sa valeur MATRICE_VIDE.


#### Q4.2 La lecture vérifie-t-elle que chaque ligne de la matrice est sur sa propre ligne de texte ? Est-ce gênant ? Justifiez le principe « tolérant en lecture, strict en écriture ».

La fonction lire_entier utilise fscanf avec le format %d, qui fait abstraction des séparateurs (espaces, tabulations, sauts de ligne \n). La lecture ne vérifie donc pas si chaque ligne du fichier correspond à une ligne de la matrice, ce qui n'est pas gênant puisque seules les dimensions n×p entêtes définissent la structure.

#### Q4.3 Après l’appel mat_lire(f, &m), le flux fest positionné après le dernier coefficient. Comment exploiter cette propriété pour stocker deux matrices dans un même fichier ?

Comme mat_lire ne lit que le nombre exact d'entiers déclarés par le header (n×pn×p) et ne ferme jamais le fichier (règle R7), le curseur de lecture reste positionné exactement après le dernier coefficient. Pour stocker deux matrices AA et BBdans un même fichier, il suffit de les écrire à la suite avec mat_ecrire(f, &A) puis mat_ecrire(f, &B). À la relecture, deux appels successifs à mat_lire sur le même flux f liront AA puis BB sans avoir à manipuler le curseur avec fseek.


#### Q4.4 Pourquoi mat_ecrire appelle-t-elle fflush avant de renvoyer MAT_OK ? Cela dispense-t-il l’appelant de tester fclose ?
Les opérations fprintf écrivent dans un tampon (buffer) en mémoire. L'appel à fflush(f) force l'écriture immédiate de ce tampon vers le système d'exploitation, ce qui permet à mat_ecrire d’intercepter un éventuel échec d'écriture (disque plein,flux interrompu) et de retourner MAT_ERR_ECRITURE. Cela ne dispense pas l'appelant de vérifier le retour de fclose(f), car la fermeture physique du fichier libère les ressources système et peut elle-même échouer (notamment sur des disques distants ou réseau NFS).

### Exercice 3
=== Exercice 3 : addition ===
[OK]    (3.a) (2 x 3) + (3 x 2) : MAT_ERR_DIMENSIONS
[OK]    (3.d) (2 x 3) + (2 x 3) : MAT_OK
[OK]    (3.c) a + b est correct
[OK]    a et b n'ont pas ete modifiees
[OK]    (3.b) le resultat possede sa propre memoire
[OK]    (3.c) INT_MAX + 1 : MAT_ERR_DEPASSEMENT
=== Exercice 3 : multiplication ===
[OK]    (3.e) (2 x 3) x (2 x 3) : MAT_ERR_DIMENSIONS
[OK]    (3.h) (2 x 3) x (3 x 2) : MAT_OK
[OK]    (3.g) a x c = (58 64 / 139 154)
[OK]    (3.f) (3 x 2) x (2 x 3) donne une matrice 3 x 3
[OK]    a et c n'ont pas ete modifiees
[OK]    (3.g) 2 x 10^10 depasse INT_MAX : MAT_ERR_DEPASSEMENT

=== Exercice 3 : cas particuliers ===
[OK]    resultat = entree refuse, a reste intacte
[OK]    (3.f) echec d'allocation : MAT_ERR_ALLOCATION, r vide
Bilan : 14 / 14 verifications reussies.


#### Q5.1 — `const Matrice *a` empêche-t-il `a->coef[0][0] = 7;` ?

Non, cette affectation est **acceptée** par le compilateur (nous l'avons vérifié). Le `const` rend en lecture seule la *structure* pointée : `a->nb_lignes = 7;` ou `a->coef = NULL;` sont refusés. Mais le champ `coef` est de type `int ** const` : le pointeur lui-même est constant, pas les `int` vers lesquels il mène, qui sont dans des blocs distincts alloués sur le tas. La protection est donc « superficielle ». Pour que le compilateur refuse aussi l'écriture des coefficients, il faudrait déclarer le champ `const int *const *coef` (et adapter l'allocation, qui devrait alors écrire via un pointeur non constant), ou ne pas exposer `coef` directement et passer par des accesseurs.


#### Q5.2 — Pourquoi refuser `mat_additionner(&a, &b, &a)` ?

Notre implémentation écrit le résultat dans `*res` après avoir calculé dans une matrice `r` distincte. Si `res == a` : `verifier_parametres` met d'abord `*res` à `MATRICE_VIDE`, donc **`a` est détruite avant d'être lue** (les `mat_est_valide` suivants échouent, ou on lirait une matrice vide) ; et même sans cela, l'affectation finale `*res = r` écraserait le pointeur `coef` de `a` sans libérer l'ancienne mémoire : fuite. Pour le produit, le calcul en place est de toute façon impossible, car chaque ligne de `a` est relue pour calculer toute une ligne de résultat. Refuser l'aliasing (`MAT_ERR_ARGUMENT`, rien n'est modifié) est la solution simple et sûre ; l'appelant peut faire `r = a + b` puis détruire `a` et réaffecter.

#### Q5.3 — Nombre de multiplications ?

Pour A (n × p) et B (p × q) : n × q coefficients, chacun nécessitant p multiplications, donc **n·p·q** multiplications. Pour deux matrices 1000 × 1000 : 1000³ = **10⁹** multiplications (un milliard), autant d'additions ; la complexité est cubique pour des matrices carrées.


#### Q5.4 — Pourquoi `int s = a + b;` puis `s < a` ne suffit pas ?

Parce que le dépassement d'un `int` signé est un **comportement indéfini** : une fois que `a + b` a débordé, on ne peut plus raisonner sur la valeur de `s`. Le compilateur est même autorisé à supposer que le dépassement n'arrive jamais, et peut donc supprimer le test lors de l'optimisation. De plus, le test `s < a` n'est valable que si `b > 0` ; pour `b < 0` le dépassement se fait par le bas et il faut un autre test. La bonne méthode est de calculer dans un type plus large (`long long`) puis de vérifier que le résultat tient dans un `int`.


### Exercice 4 
Le programme a un point de sortie unique (nettoyage) qui détruit ‘r’, ‘b’, ‘a’. Comme ‘mat_detruire’ est sans effet sur une matrice vide, il fonctionne quel que soit le chemin d'erreur.


#### Q6.1 — Pourquoi le message d'erreur est-il affiché par `main.c` et non par `mat_lire`?

Une bibliothèque ne sait pas dans quel contexte elle est utilisée. Un programme graphique afficherait une boîte de dialogue, un serveur écrirait dans un journal, un programme en ligne de commande écrit sur `stderr`, un autre voudra peut-être réessayer en silence. Si `mat_lire` écrivait elle-même, elle imposerait un comportement (et un canal de sortie) à tous ses utilisateurs et serait difficile à tester. En renvoyant un code (`MatErreur`) traduit par `mat_message_erreur`, la bibliothèque laisse l'appelant décider. De plus, seul l'appelant connaît le contexte utile (nom du fichier, opération en cours).


#### Q6.2 — Pourquoi tester `fclose` dans `sauvegarder` mais pas dans `charger` ?

En lecture, `fclose` ne peut pas faire perdre de données : toutes les données utiles ont déjà été lues et validées, et un échec éventuel de fermeture n'a aucune conséquence sur le résultat. En écriture, `fclose` vide les derniers tampons : c'est souvent là qu'apparaît un disque plein ou une erreur d'écriture différée. Ignorer son résultat ferait croire à un enregistrement réussi alors que le fichier est incomplet.


#### Q6.3 — Scénario 8 : combien de matrices à libérer ?

Trois : ‘a’ et ‘b’ (lues avec succès) et ‘r’ (calculée avec succès) possèdent toutes de la mémoire quand l'enregistrement échoue. Le ‘goto nettoyage’ mène au point de sortie unique qui appelle ‘mat_detruire(&r)’, ‘mat_detruire(&b)’, ‘mat_detruire(&a)’ : chacune est détruite exactement une fois. Vérifié par AddressSanitizer (aucune fuite).


## 5. Vérifications mémoire

### Vérifications mémoire de l'exercice 1
valgrind --leak-check=full ./test_ex1 

==5184== Memcheck, a memory error detector
==5184== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==5184== Using Valgrind-3.22.0 and LibVEX; rerun with -h for copyright info
==5184== Command: ./test_ex1
==5184== 
=== Exercice 1 : matrice.c ===
[OK]    (1.a) message pour MAT_ERR_DIMENSIONS
[OK]    (1.a) message pour MAT_ERR_DEPASSEMENT
[OK]    (1.b) une matrice 1 x 2 est valide
[OK]    (1.b) NULL n'est pas valide
[OK]    (1.b) MATRICE_VIDE n'est pas valide
[OK]    (1.b) une matrice de 0 ligne n'est pas valide
=== Exercice 1 : matrice_alloc.c ===
[OK]    (1.c) mat_allouer refuse 0 ligne
[OK]    (1.c) mat_allouer refuse -2 colonnes
[OK]    (1.c) mat_allouer refuse une dimension > MAT_DIM_MAX
[OK]    (1.e) mat_allouer(&m, 3, 4) renvoie MAT_OK
[OK]    (1.e) m a 3 lignes et 4 colonnes
[OK]    (1.d) tous les coefficients valent 0
[OK]    (1.f) apres mat_detruire, m est vide
[OK]    (1.f) un second mat_detruire est sans danger
[OK]    (1.f) mat_detruire(NULL) ne plante pas
=== Exercice 1 : echecs d'allocation simules ===
[OK]    (1.d) chaque echec renvoie MAT_ERR_ALLOCATION et laisse *res vide

Bilan : 16 / 16 verifications reussies.
Pensez a verifier l'absence de fuite : valgrind --leak-check=full ./test_ex1
==5184== 
==5184== HEAP SUMMARY:
==5184==     in use at exit: 0 bytes in 0 blocks
==5184==   total heap usage: 11 allocs, 11 frees, 1,228 bytes allocated
==5184== 
==5184== All heap blocks were freed -- no leaks are possible
==5184== 
==5184== For lists of detected and suppressed errors, rerun with: -s
==5184== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)


### Vérifications mémoire de l'exercice 2
valgrind --leak-check=full ./test_ex2 

==5825== Memcheck, a memory error detector
==5825== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==5825== Using Valgrind-3.22.0 and LibVEX; rerun with -h for copyright info
==5825== Command: ./test_ex2
==5825== 
=== Exercice 2 : affichage (verification visuelle) ===
M (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
(2.a) Vous devez voir ci-dessus 4 lignes : 1 2 3 / 4 5 6 / 7 8 9 / 10 11 12
=== Exercice 2 : ecriture ===
[OK]    ouverture de test_ex2_sortie.txt en ecriture
[OK]    (2.b) mat_ecrire renvoie MAT_OK
[OK]    (2.b) le fichier contient exactement le format attendu
[OK]    (2.b) mat_ecrire refuse une matrice vide
=== Exercice 2 : relecture ===
[OK]    (2.f) mat_lire relit le fichier : MAT_OK
[OK]    (2.e) la matrice relue est identique
[OK]    (2.e) espaces et sauts de ligne en trop sont toleres
=== Exercice 2 : fichiers incorrects ===
[OK]    (2.c) fichier vide
[OK]    (2.c) dimension nulle
[OK]    (2.c) dimension negative
[OK]    (2.e) coefficient manquant
[OK]    (2.e) donnee non numerique
[OK]    (2.e) entier trop grand pour un int
=== Exercice 2 : echec d'allocation simule ===
[OK]    (2.d) mat_lire renvoie MAT_ERR_ALLOCATION proprement

Bilan : 14 / 14 verifications reussies.
Pensez a verifier l'absence de fuite : valgrind --leak-check=full ./test_ex2
==5825== 
==5825== HEAP SUMMARY:
==5825==     in use at exit: 0 bytes in 0 blocks
==5825==   total heap usage: 51 allocs, 51 frees, 60,728 bytes allocated
==5825== 
==5825== All heap blocks were freed -- no leaks are possible
==5825== 
==5825== For lists of detected and suppressed errors, rerun with: -s
==5825== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)


### Vérifications mémoire de l'exercice 3
valgrind --leak-check=full ./test_ex3 

==6460== Memcheck, a memory error detector
==6460== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==6460== Using Valgrind-3.22.0 and LibVEX; rerun with -h for copyright info
==6460== Command: ./test_ex3
==6460== 
=== Exercice 3 : addition ===
[OK]    (3.a) (2 x 3) + (3 x 2) : MAT_ERR_DIMENSIONS
[OK]    (3.d) (2 x 3) + (2 x 3) : MAT_OK
[OK]    (3.c) a + b est correct
[OK]    a et b n'ont pas ete modifiees
[OK]    (3.b) le resultat possede sa propre memoire
[OK]    (3.c) INT_MAX + 1 : MAT_ERR_DEPASSEMENT
=== Exercice 3 : multiplication ===
[OK]    (3.e) (2 x 3) x (2 x 3) : MAT_ERR_DIMENSIONS
[OK]    (3.h) (2 x 3) x (3 x 2) : MAT_OK
[OK]    (3.g) a x c = (58 64 / 139 154)
[OK]    (3.f) (3 x 2) x (2 x 3) donne une matrice 3 x 3
[OK]    a et c n'ont pas ete modifiees
[OK]    (3.g) 2 x 10^10 depasse INT_MAX : MAT_ERR_DEPASSEMENT
=== Exercice 3 : cas particuliers ===
[OK]    resultat = entree refuse, a reste intacte
[OK]    (3.f) echec d'allocation : MAT_ERR_ALLOCATION, r vide

Bilan : 14 / 14 verifications reussies.
Pensez a verifier l'absence de fuite : valgrind --leak-check=full ./test_ex3
==6460== 
==6460== HEAP SUMMARY:
==6460==     in use at exit: 0 bytes in 0 blocks
==6460==   total heap usage: 37 allocs, 37 frees, 1,412 bytes allocated
==6460== 
==6460== All heap blocks were freed -- no leaks are possible
==6460== 
==6460== For lists of detected and suppressed errors, rerun with: -s
==6460== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)


### Vérifications mémoire de demo_matrices
valgrind --leak-check=full ./demo_matrices add donnees/A.txt donnees/B.txt R.txt
==7332== Memcheck, a memory error detector
==7332== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==7332== Using Valgrind-3.22.0 and LibVEX; rerun with -h for copyright info
==7332== Command: ./demo_matrices add donnees/A.txt donnees/B.txt R.txt
==7332== 
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
R = A + B (4 x 3) :
       26       50       87
       19       38       17
       52       96       19
       10       23        7
Résultat enregistré dans "R.txt".
==7332== 
==7332== HEAP SUMMARY:
==7332==     in use at exit: 0 bytes in 0 blocks
==7332==   total heap usage: 22 allocs, 22 frees, 14,968 bytes allocated
==7332== 
==7332== All heap blocks were freed -- no leaks are possible
==7332== 
==7332== For lists of detected and suppressed errors, rerun with: -s
==7332== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)


## 6. Démonstration finale

### Scénarios de test de ‘demo_matrices’

Les scénarios du sujet ont été exécutés avec le programme compilé par
`gcc -std=c11 -Wall -Wextra -Wpedantic -g`. Le code de sortie a été lu avec
`echo %errorlevel%` (Windows). 

La vérification automatique GitHub Actions
(valgrind sur les trois tests et sur `demo_matrices`) est verte : aucune fuite
mémoire ni accès invalide n'est signalé.

| # | Commande | Comportement observé | Code |
|---|----------|----------------------|------|

 | 1 |`add A.txt B.txt R.txt` | A, B et R = A + B sont affichées, puis « Résultat enregistré dans "R.txt" ». `R.txt` 
 | 2 | `mul A.txt C.txt R2.txt` | A (4 x 3) et C (3 x 2) sont affichées, R = A x B est de dimensions 4 x 2 puis «R├⌐sultat enregistr├⌐ dans "R2.txt».

| 3 | `add A.txt C.txt R3.txt` | affiche les matrices A et B puis Message Erreur : calcul impossible : dimensions incompatibles (A : 4 x 3, B : 3 x 2). Aucun fichier n'est créé. 

| 4 | `mul A.txt B.txt R3.txt` | affiche les matrices A et B puis Même erreur, Erreur : calcul impossible : dimensions incompatibles (A : 4 x 3, B : 4 x 3)

| 5 | `add absent.txt B.txt R3.txt` | Erreur : impossible d'ouvrir "absent.txt" : No such file or directory

| 6 | `add invalide.txt B.txt R3.txt` |Erreur : lecture de "donnees\invalide.txt" : fichier mal form├⌐

| 7 | `add tronque.txt B.txt R3.txt` |Erreur : lecture de "donnees\tronque.txt" : fichier mal form├⌐

| 8 | `add A.txt B.txt dossier_inexistant\R.txt` | Le calcul réussit et A, B, R sont affichées, puis Erreur : impossible de cr├⌐er "dossier_inexistant\R.txt" : No such file or directory

| 10 | `add A.txt` ou `foo a b c` | Message d'usage Usage : demo_matrices <add|mul> <fichier_A> <fichier_B> <fichier_R>

**Bilan des tests fournis.** `test_ex1` : 16 / 16, `test_ex2` : 14 / 14,
`test_ex3` : 14 / 14, sans aucun avertissement de compilation.


## 7. Bilan et difficultés
Nous estimons avoir effectué une bonne répartition du travail (50-50).
Répartition du travail:
Daniel : 1a,1b + correction de l’exercice 1, exercise 3, exercise 4
Eshina : 1c-1f, exercise 2 ,exercise 4

Nous avons eu recours à des tuto youtube pour apprendre à utiliser github proprement et la complétion des codes ayant été faite sur visual studio code, cela nous à faciliter les débugage. Nos erreurs les plus fréquentes étaient l’oubli d'une accolade ‘}’ ou des fautes de frappe (par exemple rse au lieu de res).

Une utilisation de l’ia gemini et claude pour trouver des alternatives à Valgrind sur Windows et MacOs car nous voulions également tester les modules sur nos ordinateurs portables respectifs. 

## 8. Annexe - Code que nous avons écrit, commenté

matrice.c 
/* (1.a) */
case MAT_ERR_DIMENSIONS:  return "dimensions incompatibles";
case MAT_ERR_DEPASSEMENT: return "dépassement de capacité";

/* (1.b) */
return m != NULL 
    && m->coef != NULL 
    && m->nb_lignes >= 1 && m->nb_lignes <= MAT_DIM_MAX 
    && m->nb_colonnes >= 1 && m->nb_colonnes <= MAT_DIM_MAX;

matrice_alloc.c
/* (1.c) */
if (nb_lignes < 1 || nb_lignes > MAT_DIM_MAX || 
    nb_colonnes < 1 || nb_colonnes > MAT_DIM_MAX) {
    return MAT_ERR_ARGUMENT;}

/* (1.d) */
for (int i = 0; i < nb_lignes; i++) {
    coef[i] = mat_calloc((size_t)nb_colonnes, sizeof **coef);
    if (coef[i] == NULL) {
        for (int k = i - 1; k >= 0; k--) {
            free(coef[k]); }
        free(coef);                  /* Libérer le tableau de pointeurs */
        return MAT_ERR_ALLOCATION;   /* Renvoyer l'erreur d'allocation */
    } }

/* (1.e) */
res->coef = coef;
res->nb_lignes = nb_lignes;
res->nb_colonnes = nb_colonnes;
return MAT_OK;

/* (1.f) */
if (m->coef != NULL) {
    for (int i = 0; i < m->nb_lignes; i++) {
        free(m->coef[i]);}
    free(m->coef); }

matrice_io.c
/* (2.a) */ 
for (int i = 0; i < m->nb_lignes; i++) { 
      for (int j = 0; j < m->nb_colonnes; j++) { 
            printf(" %8d", m->coef[i][j]); } putchar('\n'); } }

/* (2.b) */ 
for (int i = 0; i < m->nb_lignes; i++) { 
     for (int j = 0; j < m->nb_colonnes; j++) { 
          if (j == 0) { 
              if (fprintf(f, "%d", m->coef[i][j]) < 0) 
                  return MAT_ERR_ECRITURE; } 
              else { if (fprintf(f, " %d", m->coef[i][j]) < 0) 
                  returnMAT_ERR_ECRITURE; } } 

if (fputc('\n', f) == EOF) return MAT_ERR_ECRITURE; }

/* (2.c) */ 
if (nb_lignes < 1 || nb_lignes > MAT_DIM_MAX || nb_colonnes < 1 || nb_colonnes > MAT_DIM_MAX) {
return MAT_ERR_FORMAT; } 



/* (2.d) */ 
Matrice tmp; 
err = mat_allouer(&tmp, nb_lignes, nb_colonnes); 
if (err != MAT_OK) 
   return err; 

/* (2.e) */ 
for (int i = 0; i < nb_lignes; i++) { 
      for (int j = 0; j < nb_colonnes; j++) { 
           err = lire_entier(f, &tmp.coef[i][j]); 
           if (err != MAT_OK) { 
              mat_detruire(&tmp); 
              return err; } } } 

/* (2.f) */ 
*res = tmp; returnMAT_OK; 


Addition (mat_additionner)

/* 3.a */
if (a->nb_lignes != b->nb_lignes || a->nb_colonnes != b->nb_colonnes)
    return MAT_ERR_DIMENSIONS;

/* Deux matrices ne s'additionnent que si elles ont le même nombre de
 * lignes ET le même nombre de colonnes. On compare les deux séparément :
 * une 2x3 et une 3x2 ont autant de coefficients mais ne s'additionnent pas. */

/* 3.b */
juste après Matrice r = MATRICE_VIDE; :
err = mat_allouer(&r, a->nb_lignes, a->nb_colonnes);
if (err != MAT_OK)
    return err;
/* Le résultat a les dimensions de a. On l'alloue dans une matrice locale r :
 * si une erreur survient plus loin, *res reste vide et l'appelant ne reçoit
 * jamais une matrice à moitié calculée. */




/ *3.c , à la place de long long s = 0; : * /
long long s = (long long)a->coef[i][j] + b->coef[i][j];

/* La somme est faite en long long : additionner deux int ne peut pas
 * déborder d'un long long. Sans le (long long), le calcul se ferait en int
 * et pourrait déborder avant le test (comportement indéfini en C). */


/*3.d* à la fin (en supprimant les deux lignes provisoires) : * /
*res = r;
return MAT_OK;

/* Tout a réussi : on transmet r à l'appelant (règle R2). C'est lui qui
 * possède désormais la mémoire et qui devra appeler mat_detruire. */


/* Multiplication (mat_multiplier)
3.e */

if (a->nb_colonnes != b->nb_lignes)
    return MAT_ERR_DIMENSIONS;
/* Le produit a x b n'existe que si le nombre de COLONNES de a est égal
 * au nombre de LIGNES de b (a : n x p, b : p x q). */

/* 3.f juste après Matrice r = MATRICE_VIDE; : */
err = mat_allouer(&r, a->nb_lignes, b->nb_colonnes);
if (err != MAT_OK)
    return err;
/* Le résultat est de dimensions n x q : autant de lignes que a,
 * autant de colonnes que b. */





/* 3.g, dans la double boucle, après long long s = 0; : */
/* c(i,j) = somme sur k de a(i,k) x b(k,j) : ligne i de a fois colonne j de b. */ 
for (int k = 0; k < a->nb_colonnes; k++) {
    long long p = (long long)a->coef[i][k] * b->coef[k][j];
/* Avant d'ajouter p à s, on vérifie que s + p ne dépassera pas la
     * capacité d'un long long (un dépassement d'entier signé est un
     * comportement indéfini). On libère r avant de quitter : sinon fuite. */
    if ((p > 0 && s > LLONG_MAX - p)
        || (p < 0 && s < LLONG_MIN - p)) {
        mat_detruire(&r);
        return MAT_ERR_DEPASSEMENT;
    }
    s += p;
}


/* 3.h, à la fin (en supprimant les deux lignes provisoires) : */
*res = r;
return MAT_OK;
/* Même principe qu'en 3.d : transfert de propriété à l'appelant. */


/* 4.a : */
mat_afficher("A", &a);
mat_afficher("B", &b);
/* mat_afficher attend un pointeur, d'où le & devant chaque matrice. */ 



/*4.b (en supprimant (void)addition;) :
/* addition vaut 1 si l'utilisateur a tapé "add", 0 sinon. L'opérateur ? :
 * choisit donc la fonction à appeler. */
MatErreur err = addition ? mat_additionner(&a, &b, &r)
                         : mat_multiplier(&a, &b, &r);
if (err != MAT_OK) {
/* Message sur stderr : la cause, puis les dimensions de A et B pour que
     * l'utilisateur comprenne le problème. */
    fprintf(stderr, "Erreur : calcul impossible : %s ",
            mat_message_erreur(err));
    fprintf(stderr, "(A : %d x %d, B : %d x %d)\n",
            a.nb_lignes, a.nb_colonnes, b.nb_lignes, b.nb_colonnes);
    goto nettoyage;/* saute au point de sortie unique, en bas de main */ 
}

/* 4.c :
mat_afficher(addition ? "R = A + B" : "R = A x B", &r);
/* Le nom affiché dépend de l'opération demandée. */ 

/* 4.d, après l’enregistrement fourni :
/* On arrive ici seulement si tout a réussi. statut valait EXIT_FAILURE
 * depuis le début : toute sortie par goto nettoyage avant cette ligne
 * signale donc un échec. */
printf("Résultat enregistré dans \"%s\".\n", argv[4]);
statut = EXIT_SUCCESS;
