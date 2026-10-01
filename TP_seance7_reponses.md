# TP - Sortir du fichier unique : réponses

Les réponses ont été obtenues en exécutant réellement le TP : gcc 13.3, GNU make, valgrind 3.22 sous Linux. Les messages sont en anglais. Sur un système configuré en français, ils peuvent être traduits.

Hypothèse de départ : `liste_inserer` insère **en tête**. La liste s'affiche donc `50 -> 40 -> 30 -> 20 -> 10`. Si ta version de `revisions.c` insère en queue, l'ordre est inversé, et tout le reste est identique.

---

## Exercice 0

**Pourquoi ne versionne-t-on jamais les `.o` ni l'exécutable ?**
Ce sont des fichiers **générés**. On les reproduit à l'identique avec `make` à partir des sources, qui sont la seule chose à versionner. Ce sont aussi des fichiers binaires qui changent à chaque compilation : ils pollueraient chaque commit, les diffs seraient illisibles et provoqueraient des conflits de fusion. Enfin, ils dépendent de la machine (OS, architecture, compilateur), donc l'exécutable d'un collègue ne marcherait pas forcément chez toi.

---

## Exercice 1

Trous du squelette : la garde s'appelle `LISTE_H`, et les trois prototypes sont

```c
bool     liste_contient(const Maillon *tete, int valeur);
void     liste_afficher(const Maillon *tete);
void     liste_liberer(Maillon *tete);
```

Les deux `#include` contiennent `"liste.h"`.

| Question | Réponse |
| --- | --- |
| A | Chaque `.c` est compilé **séparément** et ne voit que ce qu'il inclut. `main.c` utilise le type `Maillon` (`Maillon *liste`), et `liste.c` aussi. Le type doit donc se trouver dans le fichier partagé par les deux. S'il était seulement dans `liste.c`, la compilation de `main.c` échouerait avec `unknown type name 'Maillon'`. |
| B | D'abord, `liste.c` a besoin lui-même du type `Maillon`. Ensuite, le compilateur peut ainsi **vérifier que les définitions correspondent aux déclarations** : si la signature d'une fonction diffère entre le `.h` et le `.c`, il le signale (`conflicting types`). Sans cette inclusion, l'incohérence passerait silencieusement et `main.c` appellerait la fonction avec une mauvaise signature. |

---

## Exercice 2

Sortie du programme :

```
liste     : 50 -> 40 -> 30 -> 20 -> 10 -> NULL
longueur  : 5
contient 30 : oui
liberee
```

| Question | Réponse |
| --- | --- |
| A | On obtient **deux** fichiers `.o` : `main.o` et `liste.o`. Il n'y a pas de `liste.h.o`, car un `.h` n'est pas une unité de compilation. Il n'est jamais compilé seul : le préprocesseur **recopie son texte** dans chaque `.c` qui l'inclut. Son contenu se retrouve donc dans `main.o` et dans `liste.o`. |
| B | Cette commande **recompile tout à chaque fois**. Les deux étapes séparées permettent de ne recompiler que le `.c` modifié et de réutiliser les `.o` déjà à jour. Sur un projet de centaines de fichiers, la différence se compte en minutes. C'est sur ce principe que repose `make`. |

---

## Exercice 3

| Cas | Premier message exact | Compilation ou lien |
| --- | --- | --- |
| 1 | `/usr/bin/ld: main.o: in function 'main':` puis `main.c:(.text+0x35): undefined reference to 'liste_inserer'` (et de même pour les quatre autres fonctions), puis `collect2: error: ld returned 1 exit status` | **Lien** |
| 2 | `main.c:5:5: error: unknown type name 'Maillon'` | Compilation |
| 3 | `liste.h:4:16: error: redefinition of 'struct Maillon'` | Compilation |

| Question | Réponse |
| --- | --- |
| 1 | Le **cas 1**. On le voit à plusieurs indices : le message est préfixé par `/usr/bin/ld` (l'éditeur de liens), il se termine par `ld returned 1 exit status`, et il ne donne pas de numéro de ligne mais un décalage dans le code machine (`.text+0x35`). L'éditeur de liens ne voit plus le source, seulement les `.o`. |
| 2 | Le premier : `unknown type name 'Maillon'`. Les autres messages (`implicit declaration of function 'liste_inserer'`, `assignment to 'int *' from 'int'`, etc.) sont des **conséquences** de la même cause, l'en-tête absent. Il faut toujours corriger le premier message et recompiler. *Remarque : gcc 13 émet les « implicit declaration » comme avertissements. Depuis gcc 14, ce sont des erreurs.* |
| 3 | Ce cas apparaît dès qu'un **en-tête en inclut un autre**. Par exemple, `test.h` fait `#include "liste.h"`, et `main.c` inclut à la fois `liste.h` et `test.h`. `liste.h` est alors lu deux fois de façon indirecte, sans qu'aucune ligne ne soit dupliquée à la main. |

---

## Exercice 4

Trous du squelette : `main.o: main.c liste.h` et `liste.o: liste.c liste.h`.

`make clean` puis `make` exécutent :

```
gcc -Wall -Wextra -std=c11 -g -c main.c
gcc -Wall -Wextra -std=c11 -g -c liste.c
gcc -Wall -Wextra -std=c11 -g -o demo main.o liste.o
```

Le second `make` affiche : `make: 'demo' is up to date.`

| Question | Réponse |
| --- | --- |
| A | `make` compare les **dates de modification**. `demo` est plus récent que `main.o` et `liste.o`, qui sont eux-mêmes plus récents que leurs dépendances (`.c` et `liste.h`). Aucune cible n'est donc périmée, et il n'y a rien à refaire. |
| B (message exact) | `Makefile:2: *** missing separator.  Stop.` (en français : `*** séparateur manquant. Arrêt.`) |

---

## Exercice 5

| Étape | Ce que make recompile |
| --- | --- |
| 2, avec la dépendance | `main.o` **et** `liste.o`, puis le lien de `demo` |
| 4, sans la dépendance | **Seulement** `liste.o`, puis le lien. `main.o` n'est pas recompilé. |

| Question | Réponse |
| --- | --- |
| A | Avec la dépendance, modifier `liste.h` recompile tous les `.c` qui l'incluent. Sans elle, `make` ignore que `main.c` dépend de `liste.h`, et il **garde un `main.o` périmé**. |
| B | Un exécutable **incohérent**. `liste.o` est compilé avec la nouvelle structure, tandis que `main.o` utilise encore l'ancienne (ancienne taille, anciens décalages des champs). Les deux moitiés du programme ne sont plus d'accord sur la forme d'un `Maillon`. Le lien réussit sans aucun avertissement, mais le comportement est indéfini : valeurs fausses, corruption mémoire, plantage. C'est le pire type de bug, car rien ne le signale. |

Le Makefile générique (`%.o: %.c liste.h`) produit exactement les mêmes trois commandes, avec en plus `-o $@`.

---

## Exercice 6

Trous du squelette : `if (p != NULL) blocs++;`, puis `if (p != NULL) { blocs--; free(p); }`, puis `return blocs;`.

La fuite introduite est une seconde liste de trois éléments, `autre`, qui n'est jamais libérée.

| Mesure | Sans la fuite | Avec la fuite |
| --- | --- | --- |
| Compteur après construction | 5 | 8 |
| Compteur après libération | 0 | 3 |

| Question | Réponse |
| --- | --- |
| A | Ce sont des **détails internes** du module. `static` leur donne une liaison interne : ils sont invisibles hors de `liste.c`. Ainsi, `main.c` ne peut ni modifier le compteur, ni appeler `suivi_malloc` à tort, et il n'y a pas de conflit de noms avec un autre module. L'interface publique se limite à ce dont l'utilisateur a besoin, c'est-à-dire **lire** la valeur avec `liste_blocs_en_circulation`. |
| B | Sans le test dans `suivi_malloc` : un `malloc` raté (qui renvoie `NULL`) serait compté comme un bloc alloué, alors qu'aucun `free` ne viendra jamais le rendre. Le compteur signalerait une **fausse fuite**. Sans le test dans `suivi_free` : `free(NULL)` est légal et ne fait rien, mais le compteur serait décrémenté quand même. Il **sous-estimerait** alors les blocs en circulation, pourrait devenir négatif ou **masquer une vraie fuite** (une fuite plus un `free(NULL)` donnerait 0). |
| C | **Non**, il dit seulement *combien* de blocs manquent. Pour trouver *où*, on procède par **dichotomie** : on affiche le compteur à plusieurs endroits de `main` (après chaque construction et après chaque libération), ou on désactive des portions de code, jusqu'à isoler la portion après laquelle le compteur ne revient pas à sa valeur attendue. |

---

## Exercice 7

Sans la fuite, les deux dernières lignes du rapport sont :

```
All heap blocks were freed -- no leaks are possible
ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

Avec la fuite :

```
48 (16 direct, 32 indirect) bytes in 1 blocks are definitely lost in loss record 2 of 2
   at 0x4846828: malloc (in .../vgpreload_memcheck-amd64-linux.so)
   by 0x109311: suivi_malloc (liste.c:11)
   by 0x109393: liste_inserer (liste.c:28)
   by 0x109211: main (main.c:10)
```

| Mesure | Sans la fuite | Avec la fuite |
| --- | --- | --- |
| `definitely lost` | 0 (aucune fuite) | 16 bytes in 1 blocks |
| `indirectly lost` | 0 | 32 bytes in 2 blocks |
| `total heap usage` | 6 allocs, 6 frees, 4,176 bytes | 9 allocs, 6 frees, 4,224 bytes |
| Votre compteur | 0 | 3 |

Au total, 48 octets sont perdus en 3 blocs (un maillon fait 16 octets en 64 bits).

| Question | Réponse |
| --- | --- |
| A | La ligne `main.c:10` : `for (...) autre = liste_inserer(autre, i);`. **Ce n'est pas** la ligne où le `free` a été oublié. valgrind indique **où la mémoire a été allouée**, pas où elle aurait dû être rendue, parce qu'un oubli n'a pas de ligne. Le `liste_liberer(autre);` manquant devait se trouver à la fin de `main`, avant le `return 0`. |
| B | **1 bloc** en `definitely lost` (16 octets) et **2 blocs** en `indirectly lost` (32 octets). Seule la **tête** de la liste est perdue directement, car c'est la variable `autre` qui pointait dessus, et elle disparaît à la fin de `main`. Les deux maillons suivants ne sont plus accessibles que *via* le champ `suivant` d'un bloc déjà perdu : ils sont donc perdus indirectement. Libérer la tête avec `liste_liberer` réglerait les trois. |
| C | Sans fuite, N = 6 et M = 6. Avec fuite, N = 9 et M = 6. N vaut le nombre de maillons **plus 1**. Le bloc supplémentaire est le **tampon de sortie de `stdout`** (4096 octets), que la bibliothèque C alloue au premier `printf` et libère à la sortie. On le retrouve dans le calcul : 4176 = 5 × 16 + 4096. Notre compteur ne le voit pas, car il passe par `malloc` directement et non par `suivi_malloc`. |

---

## Exercice 8

| Observation | Réponse |
| --- | --- |
| Sortie affichée, sans outil | `42` |
| Code de sortie, sans outil | `0` |
| Message de l'outil | valgrind : `Invalid write of size 4 at main (deborde.c:8) Address 0x... is 0 bytes after a block of size 20 alloc'd`, suivi d'un `Invalid read of size 4` à la ligne 9. ASan : `ERROR: AddressSanitizer: heap-buffer-overflow ... WRITE of size 4 ... is located 0 bytes after 20-byte region` |

| Question | Réponse |
| --- | --- |
| A | **Non** : il y a un `malloc` et un `free`, la comptabilité est juste. Le compteur aurait affiché 0, donc **rien d'anormal**. Il ne mesure que l'équilibre des allocations, pas la validité des accès. |
| B | Le **20** est la taille du bloc alloué : `5 * sizeof(int)` = 5 × 4 octets. Le **0** est la distance entre la fin du bloc et l'adresse fautive : `t[5]` commence exactement à l'octet 20, c'est-à-dire juste après la fin du bloc. Pour `t[6]`, le message serait `4 bytes after a block of size 20` (vérifié). |
| C | Un test qui « passe » prouve seulement que le programme a donné le bon résultat **cette fois-ci, sur cette machine**. Il ne prouve pas que le programme est correct. Un comportement indéfini peut sembler fonctionner (ici, l'octet après le bloc était libre), puis casser avec un autre compilateur, d'autres options ou d'autres données. Il faut combiner les tests avec des outils qui vérifient les accès mémoire. |
| D | Le **compteur** sert à surveiller en continu les fuites d'un module : il ne coûte rien, fonctionne partout (même là où valgrind n'existe pas) et peut s'intégrer à un test automatique. Il ne dit ni où est la fuite, ni rien sur les accès invalides. **valgrind** (ou ASan) sert à **localiser** une fuite (pile d'appels, lignes), à détecter les **débordements**, les lectures de mémoire non initialisée et les doubles `free`. On le lance pour déboguer, avant une livraison, ou dans une cible `make test`. |

---

## Exercice 9

Trous du squelette : `if (tete == NULL) return false;`, `int max = tete->valeur;`, `m = tete->suivant`, `if (m->valeur > max)`.

Sortie du programme :

```
blocs apres construction : 5
liste     : 50 -> 40 -> 30 -> 20 -> 10 -> NULL
longueur  : 5
contient 30 : oui
maximum   : 50
maximum(NULL) : liste vide
liberee
blocs apres liberation : 0
```

valgrind : `All heap blocks were freed -- no leaks are possible`, `ERROR SUMMARY: 0 errors`.

| Question | Réponse |
| --- | --- |
| A | J'ai modifié **trois fichiers** : `liste.h` (déclaration), `liste.c` (définition) et `main.c` (appel). `make` a recompilé **`main.o` et `liste.o`**, puis refait le lien. Les deux `.o` dépendent de `liste.h`, qui a été modifié. |
| B | `-1` est une **valeur légitime** : une liste peut contenir des entiers négatifs, et si son maximum vaut `-1`, l'appelant ne peut pas savoir si la liste est vide ou non. Une « valeur sentinelle » prise dans le domaine des résultats rend la réponse ambiguë. Avec un `bool` pour le succès et un paramètre de sortie pour la valeur, on sépare clairement les deux informations, et on ne peut pas oublier de traiter le cas vide. |
