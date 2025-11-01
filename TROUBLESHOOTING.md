# Guide de Dépannage - TP Ansible Adminer

## ❓ Questions fréquemment posées (FAQ)

### Q: Où accéder à Adminer?
**R:** `http://localhost/adminer/adminer.php`

### Q: Quels sont les identifiants par défaut?
**R:**
- Serveur: `for-target-3`
- Utilisateur: `adminer_user`
- Mot de passe: Voir dans `.env.example` ou `vault/secrets.yml`

### Q: Combien de temps prend le déploiement?
**R:** ~5-10 minutes pour tous les playbooks

### Q: Puis-je relancer les playbooks?
**R:** Oui ! Ils sont idempotents (aucun problème à relancer)

### Q: Où sont les logs Ansible?
**R:** Dans `logs/ansible.log`

### Q: Comment ajouter d'autres conteneurs?
**R:** Éditer `docker-compose.yml` pour ajouter des services

---

## 🆘 Erreurs courants et solutions

### ❌ ERREUR 1 : "Cannot connect to Docker daemon"

**Symptôme :**
```
error during connect: This error may indicate the docker daemon is not running
```

**Causes possibles :**
1. Docker n'est pas lancé
2. Le daemon Docker n'est pas actif
3. Permissions insuffisantes

**Solutions :**

```bash
# Windows/Mac : Relancer Docker Desktop
# Linux : Démarrer le daemon
sudo systemctl start docker

# Vérifier
docker ps

# Si problème de permissions (Linux)
sudo usermod -aG docker $USER
# Puis relancer votre session
```

---

### ❌ ERREUR 2 : "no inventory was parsed"

**Symptôme :**
```
[WARNING]: No inventory was parsed, only implicit localhost is available
```

**Cause :** Ansible ne trouve pas l'inventaire

**Solution :**

```bash
# Vérifier que inventory.ini existe
ls -la inventory.ini

# Lancer Ansible avec le bon inventaire
ansible-playbook -i inventory.ini site.yml

# Ou relancer depuis le conteneur
docker-compose exec controller ansible-playbook site.yml -v
```

---

### ❌ ERREUR 3 : "Permission denied (publickey)"

**Symptôme :**
```
Permission denied (publickey,password).
```

**Causes possibles :**
1. Clés SSH mal générées
2. Permissions SSH incorrectes
3. Conteneurs pas prêts pour SSH

**Solutions :**

```bash
# Vérifier les clés
# Vérifier les clés SSH (déjà fournies par le TP)
ls -la ssh-keys/
# Doit afficher : id_rsa, id_rsa.pub, known_hosts, .keep

# Vérifier les permissions
stat ssh-keys/id_rsa
# Mode doit être : 0600

# Corriger les permissions si nécessaire
chmod 600 ssh-keys/id_rsa
chmod 644 ssh-keys/id_rsa.pub

# IMPORTANT : Les clés SSH sont FOURNIES par le TP
# Vous n'avez PAS besoin de les régénérer !
# Si les clés sont corrompues, les récupérer du TP original

# Attendre que les conteneurs soient prêts
sleep 30

# Retester
docker-compose exec controller ansible -i /ansible/inventory.ini all -m ping
```

---

### ❌ ERREUR 4 : "Address already in use"

**Symptôme :**
```
ERROR: for <service> Error response from daemon: 
  driver failed programming external connectivity on endpoint <name>
```

**Cause :** Un port est déjà utilisé

**Solutions :**

```bash
# Trouver quel processus utilise le port
# Windows PowerShell
Get-NetTCPConnection -LocalPort 80 -ErrorAction SilentlyContinue | Select-Object OwningProcess
tasklist /FI "PID eq <PID>"

# Linux/Mac
lsof -i :80
# ou
netstat -tlnp | grep :80

# Arrêter le service conflictuel
# OU modifier les ports dans docker-compose.yml

# Puis relancer
docker-compose up -d
```

---

### ❌ ERREUR 5 : "Failed to download Adminer"

**Symptôme :**
```
FAILED - RETRYING - HTTP Error 404: Not Found
```

**Cause :** Problème de connectivité internet ou URL invalide

**Solutions :**

```bash
# Tester la connectivité depuis le conteneur
docker exec for-target-1 curl -I https://github.com/vrana/adminer/releases/

# Vérifier l'URL dans group_vars/web_servers.yml
cat group_vars/web_servers.yml | grep adminer_download_url

# Mettre à jour si URL est incorrecte
nano group_vars/web_servers.yml

# Relancer le playbook
docker-compose exec controller ansible-playbook 02-deploy-adminer.yml -v
```

---

### ❌ ERREUR 6 : "MySQL authentication failed"

**Symptôme :**
```
mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 1045 (28000): Access denied for user 'root'@'localhost'
```

**Causes possibles :**
1. Mot de passe incorrect
2. Utilisateur n'existe pas
3. MySQL n'a pas complètement démarré

**Solutions :**

```bash
# Attendre que MySQL soit prêt
sleep 15

# Tester avec le mot de passe correct
docker exec for-target-3 mysql -u root -p"RootPasswordMySQL8_0_Secure2025!" -e "SELECT VERSION();"

# Vérifier les utilisateurs
docker exec for-target-3 mysql -u root -p"RootPasswordMySQL8_0_Secure2025!" -e "SELECT user, host FROM mysql.user;"

# Réinitialiser le password root si nécessaire
docker exec for-target-3 mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword123';"
```

---

### ❌ ERREUR 7 : "Cannot find Adminer file"

**Symptôme :**
```
File not found when accessing /adminer/adminer.php
```

**Cause :** Adminer n'a pas été téléchargé correctement

**Solutions :**

```bash
# Vérifier que le fichier existe
docker exec for-target-1 ls -la /var/www/html/adminer/

# Vérifier les permissions
docker exec for-target-1 stat /var/www/html/adminer/adminer.php

# Vérifier les erreurs Apache
docker exec for-target-1 tail -20 /var/log/apache2/error.log

# Relancer le playbook Adminer
docker-compose exec controller ansible-playbook 02-deploy-adminer.yml -v

# Attendre et retester
curl -I http://localhost/adminer/adminer.php
```

---

### ❌ ERREUR 8 : "Vault password not found"

**Symptôme :**
```
Vault password (--vault-password-file) was not specified
```

**Cause :** Le fichier `.vault-password` n'existe pas

**Solutions :**

```bash
# Créer le fichier
echo "SecureVaultPassword2025!" > .vault-password

# Donner les permissions
chmod 600 .vault-password

# Vérifier
ls -la .vault-password

# Relancer avec vault
docker-compose exec controller ansible-playbook 03-deploy-database.yml -v
```

---

### ❌ ERREUR 9 : "Playbook failed on all hosts"

**Symptôme :**
```
FAILED - RETRYING - Playbook failed on x out of y hosts, 0 parsed
```

**Cause générale :** Erreur dans le playbook ou configuration

**Solutions :**

```bash
# Voir les erreurs détaillées
docker-compose exec controller ansible-playbook <playbook>.yml -vvv

# Vérifier la syntaxe
ansible-playbook <playbook>.yml --syntax-check

# Vérifier les variables
ansible-inventory -i inventory.ini --vars | head -50

# Relancer le playbook
docker-compose exec controller ansible-playbook <playbook>.yml -v

# Si continue à échouer, voir les logs détaillés
docker-compose logs | tail -100
```

---

### ❌ ERREUR 10 : "Apache won't start"

**Symptôme :**
```
Job for apache2.service failed
```

**Cause :** Erreur de configuration Apache

**Solutions :**

```bash
# Vérifier la syntaxe Apache
docker exec for-target-1 apache2ctl configtest

# Voir les erreurs
docker exec for-target-1 tail -50 /var/log/apache2/error.log

# Activer mod_php si absent
docker exec for-target-1 a2enmod php8.2

# Activer la bonne config
docker exec for-target-1 a2ensite adminer.conf

# Tester again
docker exec for-target-1 apache2ctl configtest

# Redémarrer
docker exec for-target-1 systemctl restart apache2

# Vérifier l'écoute
docker exec for-target-1 ss -tlnp | grep :80
```

---

### ❌ ERREUR 11 : "Connexion Adminer → MySQL échoue"

**Symptôme :**
```
#1045 - Access denied for user 'adminer_user'@'for-target-1'
```

**Cause :** Utilisateur MySQL n'a pas les permissions depuis for-target-1

**Solutions :**

```bash
# Vérifier que l'utilisateur existe
docker exec for-target-3 mysql -u root -p"RootPassword" -e "SELECT user, host FROM mysql.user WHERE user='adminer_user';"

# Vérifier les permissions
docker exec for-target-3 mysql -u root -p"RootPassword" -e "SHOW GRANTS FOR 'adminer_user'@'%';"

# Recréer l'utilisateur si nécessaire
docker exec for-target-3 mysql -u root -p"RootPassword" -e "
  DROP USER IF EXISTS 'adminer_user'@'%';
  CREATE USER 'adminer_user'@'%' IDENTIFIED BY 'AdminerPassword';
  GRANT ALL PRIVILEGES ON *.* TO 'adminer_user'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
"

# Tester depuis for-target-1
docker exec for-target-1 mysql -h for-target-3 -u adminer_user -p"AdminerPassword" -e "SELECT DATABASE(), USER();"

# Relancer le playbook
docker-compose exec controller ansible-playbook 03-deploy-database.yml -v
```

---

### ❌ ERREUR 12 : "Cannot reach for-target-3 from for-target-1"

**Symptôme :**
```
ping: cannot reach for-target-3: Temporary failure in name resolution
```

**Cause :** Problème réseau Docker

**Solutions :**

```bash
# Vérifier le réseau Docker
docker network ls | grep ansible

# Vérifier que les conteneurs sont dans le réseau
docker network inspect ansible_network

# Redémarrer les conteneurs
docker-compose restart

# Attendre
sleep 10

# Retester
docker exec for-target-1 ping -c 2 for-target-3

# Si toujours problème, recréer le réseau
docker-compose down
docker-compose up -d
```

---

### ❌ ERREUR 13 : "Out of memory"

**Symptôme :**
```
OOM Killer invoked
ou
Cannot allocate memory
```

**Cause :** Pas assez de RAM

**Solutions :**

```bash
# Vérifier la RAM disponible
docker system df

# Libérer de l'espace
docker system prune -a
docker volume prune

# Augmenter la RAM Docker
# Windows/Mac : Docker Desktop Settings → Resources → Memory

# Ou réduire les services lancés
docker-compose down
# Relancer après un redémarrage complet
```

---

### ❌ ERREUR 14 : "Playbook timeout"

**Symptôme :**
```
timed out waiting for privilege escalation prompt
```

**Cause :** Sudo prend trop de temps

**Solutions :**

```bash
# Augmenter le timeout dans ansible.cfg
nano ansible.cfg

# Ajouter/modifier :
timeout = 60

# Ou relancer avec timeout augmenté
ANSIBLE_TIMEOUT=60 ansible-playbook site.yml -v

# Ou dans docker-compose
docker-compose exec controller env ANSIBLE_TIMEOUT=60 ansible-playbook site.yml -v
```

---

## 🔧 Commandes de debug utiles

### Afficher les logs détaillés

```bash
# Logs Docker
docker-compose logs -f

# Logs spécifique d'un service
docker-compose logs -f for-target-1

# Logs Ansible
tail -f logs/ansible.log

# Logs Apache
docker exec for-target-1 tail -f /var/log/apache2/error.log

# Logs MySQL
docker exec for-target-3 tail -f /var/log/mysql/error.log
```

### SSH dans un conteneur

```bash
docker exec -it for-controller bash
docker exec -it for-target-1 bash
docker exec -it for-target-3 bash

# Exécuter une commande directement
docker exec for-target-1 ls -la /var/www/html/
```

### Vérifier les variables Ansible

```bash
# Toutes les variables
ansible-inventory -i inventory.ini --vars

# Variables d'un hôte spécifique
ansible-inventory -i inventory.ini --host for-target-1

# Variables d'un groupe
ansible-inventory -i inventory.ini --group web_servers
```

### Tester une tâche spécifique

```bash
# Exécuter une tâche spécifique d'un playbook
docker-compose exec controller ansible-playbook 02-deploy-adminer.yml -v --tags "apache"

# OU
docker-compose exec controller ansible-playbook 02-deploy-adminer.yml -v --skip-tags "adminer"
```

---

## 📞 Obtenir de l'aide

### Avant de demander aide :

1. **Vérifier les logs** : `docker-compose logs`
2. **Relancer les conteneurs** : `docker-compose restart`
3. **Vérifier la syntaxe** : `ansible-playbook --syntax-check`
4. **Consulter ce guide** : Chercher le mot-clé de l'erreur
5. **Lire les docs** : INSTALLATION.md, ARCHITECTURE.md

### Informations à fournir quand vous demandez aide :

```
1. Commande lancée
2. Message d'erreur complet
3. Output de 'docker-compose ps'
4. Logs pertinents (docker-compose logs)
5. Votre OS et version Docker
6. Étapes déjà essayées
```

---

## ✅ Checklist de diagnostic

Si quelque chose ne marche pas :

```
[ ] Les conteneurs tournent-ils ?
    docker-compose ps

[ ] Ansible peut-il se connecter ?
    docker-compose exec controller ansible all -m ping

[ ] Apache écoute-t-il sur le port 80 ?
    docker exec for-target-1 ss -tlnp | grep :80

[ ] MySQL écoute-t-il sur le port 3306 ?
    docker exec for-target-3 ss -tlnp | grep :3306

[ ] Le fichier Adminer existe-t-il ?
    docker exec for-target-1 ls -la /var/www/html/adminer/adminer.php

[ ] Les utilisateurs MySQL existent-ils ?
    docker exec for-target-3 mysql -u root -pPASSWORD -e "SELECT user FROM mysql.user;"

[ ] La connectivité réseau fonctionne-t-elle ?
    docker exec for-target-1 ping -c 2 for-target-3

[ ] Les logs montrent-ils des erreurs ?
    docker-compose logs | grep -i error
```

---

**Guide de dépannage complet ! 🎯**
