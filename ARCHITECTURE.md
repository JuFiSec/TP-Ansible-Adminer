# Architecture du TP Ansible Adminer

## 📐 Vue d'ensemble

Ce projet déploie une infrastructure complète d'Adminer 4.8.1 utilisant Ansible pour orchestrer :
- **1 serveur Web** (Apache2 + PHP 8.2 + Adminer)
- **1 serveur Base de Données** (MySQL 8.0)
- **1 contrôleur Ansible** pour l'orchestration

---

## 🏗️ Architecture générale

``` mermaid
graph TB
    USER["👤 Utilisateur<br/>Navigateur"]
    
    subgraph DOCKER["DOCKER NETWORK 10.10.10.0/24"]
        CONTROLLER["🎛️ ANSIBLE CONTROLLER<br/>Ansible 2.14+<br/>Python 3.10"]
        WEB["🌐 WEB SERVER<br/>Apache2 + PHP 8.2<br/>Adminer 4.8.1"]
        DB["🗄️ DATABASE SERVER<br/>MySQL 8.0"]
    end
    
    USER -->|HTTP:80| WEB
    USER -->|SSH:22| CONTROLLER
    CONTROLLER -->|SSH:22| WEB
    CONTROLLER -->|SSH:22| DB
    WEB -->|TCP:3306| DB
    
    style DOCKER fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style CONTROLLER fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style WEB fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    style DB fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    style USER fill:#fce4ec,stroke:#880e4f,stroke-width:2px
```

---

## 🔗 Flux de communication

```
1. UTILISATEUR
   ▼
2. Navigateur Web
   │
   ├─ http://localhost/adminer/adminer.php
   │  (Port forwarding Docker si nécessaire)
   │
   ▼
3. Apache2 (for-target-1)
   │
   ├─ Exécute Adminer PHP
   │
   ├─ Adminer se connecte à MySQL via le réseau Docker
   │
   ▼
4. MySQL 8.0 (for-target-3)
   │
   ├─ Authentification adminer_user
   ├─ Base de données testdb
   ├─ Affichage des tables et données
   │
   ▼
5. Réponse HTTP vers le navigateur
```

---

## 📦 Structure du projet

```
tp-ansible-adminer/
├── docker-compose.yml              ← Configuration Docker (3 services)
├── ansible.cfg                     ← Configuration Ansible
├── inventory.ini                   ← Inventaire des hôtes
├── Makefile                        ← Commandes pratiques
│
├── .docker/                        ← Images Docker personnalisées
│   ├── ansible-controller/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   │
│   └── target/
│       ├── Dockerfile
│       └── entrypoint.sh
│
├── ansible-config/                 ← Configuration Ansible (montée en volume)
│   ├── 01-init-servers.yml        ← Playbook 1 : Initialisation
│   ├── 02-deploy-adminer.yml      ← Playbook 2 : Déploiement Adminer
│   ├── 03-deploy-database.yml     ← Playbook 3 : Déploiement MySQL
│   ├── site.yml                   ← Orchestration complète
│   ├── ansible.cfg
│   ├── inventory.ini
│   │
│   ├── group_vars/
│   │   ├── all.yml                ← Variables communes
│   │   ├── web_servers.yml        ← Variables serveurs web
│   │   └── db_servers.yml         ← Variables serveurs BD
│   │
│   ├── templates/                 ← Templates Jinja2
│   │   └── (à créer si besoin)
│   │
│   ├── files/
│   │   └── init_db.sql            ← Script d'initialisation BD
│   │
│   └── vault/
│       ├── secrets.yml            ← Secrets chiffrés Vault
│       └── .vault-password        ← Password Vault
│
├── ssh-keys/                       ← Clés SSH (montées en volume)
│   ├── id_rsa
│   └── id_rsa.pub
│
├── logs/                           ← Logs (montés en volume)
│   ├── ansible.log
│   ├── target-1/
│   └── target-3/
│
├── .gitignore                      ← Fichiers à ignorer pour Git
├── .env.example                    ← Template des variables sensibles
│
├── TESTS.md                        ← Guide de test
├── ARCHITECTURE.md                 ← Ce fichier
└── README.md                       ← (À créer à la fin)
```

---

## 🔄 Flux d'exécution Ansible

### Playbook 01 : Initialisation des serveurs

```
01-init-servers.yml
├── Groupe : [targets] (tous les serveurs)
├── Tâches :
│   ├── apt update/upgrade
│   ├── Installation paquets essentiels
│   ├── Configuration Python 3.10
│   ├── Création utilisateur 'ansible'
│   ├── Configuration SSH (clés)
│   ├── Configuration sudo (NOPASSWD)
│   ├── Création répertoires de logs
│   └── Configuration système (timezone, locale)
└── Résultat : Serveurs prêts pour déploiement
```

### Playbook 02 : Déploiement Adminer

```
02-deploy-adminer.yml
├── Groupe : [web_servers]
├── Tâches :
│   ├── Installation Apache2
│   ├── Activation modules Apache (php, rewrite, proxy)
│   ├── Installation PHP 8.2
│   ├── Activation module PHP Apache
│   ├── Configuration PHP (php.ini)
│   ├── Téléchargement Adminer 4.8.1
│   ├── Création VirtualHost Apache
│   ├── Installation MySQL client
│   └── Vérification HTTP
└── Résultat : Adminer accessible via HTTP
```

### Playbook 03 : Déploiement Database

```
03-deploy-database.yml
├── Groupe : [db_servers]
├── Variables : vault/secrets.yml (chiffrées)
├── Tâches :
│   ├── Installation MySQL 8.0
│   ├── Configuration sécurité (utilisateurs anonymes, BD test)
│   ├── Création bases de données (testdb, adminer_db)
│   ├── Création utilisateurs MySQL (adminer_user)
│   ├── Initialisation données SQL (si fichier existe)
│   └── Vérification connectivité
└── Résultat : MySQL fonctionnel avec données
```

### Playbook Site : Orchestration complète

```
site.yml
├── Import playbook 01
├── Import playbook 02
├── Import playbook 03
├── Vérifications finales
└── Résumé d'exécution
```

---

## 🗝️ Secrets et Sécurité

### Gestion des secrets

```
.vault-password (LOCAL, .gitignored)
    │
    ├─ Contient : "SecureVaultPassword2025!"
    └─ Utilisé pour : déchiffrer vault/secrets.yml
    
vault/secrets.yml (CHIFFRÉ sur GitHub)
    │
    ├─ mysql_root_password
    ├─ adminer_user_password
    ├─ app_user_password
    └─ vault_password

.env.example (PUBLIC sur GitHub)
    │
    ├─ Template des secrets
    ├─ Montré au prof
    └─ Permet reconstitution facile
```

### Hiérarchie des variables Ansible

```
1. group_vars/all.yml           ← Variables communes TOUS les serveurs
2. group_vars/web_servers.yml   ← Variables spécifiques WEB
3. group_vars/db_servers.yml    ← Variables spécifiques DB
4. vault/secrets.yml            ← Secrets chiffrés
5. Ligne de commande             ← Override (si -e utilisé)
```

---

## 🌐 Réseau Docker

```
┌─────────────────────────────────────────┐
│  RÉSEAU DOCKER BRIDGE (ansible_network) │
│  Subnet : 10.10.10.0/24                │
│  Gateway : 10.10.10.1                  │
└───────────┬───────────┬─────────────────┘
            │           │
            ▼           ▼
    ┌───────────────┐  ┌──────────────────┐
    │ for-target-1  │  │ for-target-3     │
    │ 10.10.10.2    │  │ 10.10.10.3       │
    │ WEB           │  │ DB               │
    └───────────────┘  └──────────────────┘
```

**Communication** :
- `for-target-1` ↔ `for-target-3` : DNS/IP résolvables automatiquement
- Depuis `for-target-1` → `for-target-3:3306` pour MySQL
- Aucun port exposed (sauf HTTP si port mapping)

---

## 🔐 Authentification

### Ansible → Conteneurs

```
ansible@for-target-1
    ↓
/root/.ssh/id_rsa (clé privée)
    ↓
~/.ssh/authorized_keys (clé publique du conteneur)
    ↓
Port 22 SSH
    ↓
✓ Connexion réussie
```

### Adminer → MySQL

```
adminer_user
    ↓
Password : adminer_user_password
    ↓
Host : from-target-3
    ↓
Port : 3306
    ↓
✓ Authentification MySQL réussie
```

---

## 📊 Services et ports

| Service | Conteneur | Port | Protocole | Accessible |
|---------|-----------|------|-----------|-----------|
| SSH | for-controller | 22 | TCP | Interne |
| SSH | for-target-1 | 22 | TCP | Interne |
| SSH | for-target-3 | 22 | TCP | Interne |
| HTTP | for-target-1 | 80 | TCP | Interne (Port mapping optionnel) |
| MySQL | for-target-3 | 3306 | TCP | Interne (Port mapping optionnel) |

---

## 🔧 Variables et Configuration

### Variables globales (all.yml)

- `system_update`: Mise à jour système automatique
- `timezone`: Fuseau horaire (UTC par défaut)
- `locale`: Locale système
- `common_packages`: Paquets essentiels

### Variables Web (web_servers.yml)

- `apache2_port`: Port Apache (80)
- `php_version`: Version PHP (8.2)
- `adminer_version`: Version Adminer (4.8.1)
- `apache2_document_root`: Racine web

### Variables DB (db_servers.yml)

- `mysql_version`: Version MySQL (8.0)
- `mysql_bind_address`: Adresse d'écoute (0.0.0.0)
- `mysql_databases`: Bases créées (testdb, adminer_db)
- `mysql_users`: Utilisateurs MySQL

---

## 🚀 Flux de déploiement complet

```
1. USER ─────────► make up / docker-compose up
                   │
2. DOCKER COMPOSE ─► Lance 3 services
                   │
                   ├─ for-controller (Ansible)
                   ├─ for-target-1 (Web)
                   └─ for-target-3 (DB)
                   │
3. ANSIBLE ────────► Entrypoint lance Ansible
                   │
4. PLAYBOOK 01 ────► init-servers.yml
                   ├─ apt update/upgrade
                   ├─ Installation essentiels
                   ├─ Configuration utilisateurs
                   └─ Configuration SSH
                   │
5. PLAYBOOK 02 ────► deploy-adminer.yml
                   ├─ Installation Apache2 + PHP
                   ├─ Téléchargement Adminer
                   ├─ Configuration VirtualHost
                   └─ Vérification HTTP
                   │
6. PLAYBOOK 03 ────► deploy-database.yml
                   ├─ Installation MySQL
                   ├─ Création bases/utilisateurs
                   ├─ Initialisation données
                   └─ Vérification connexion
                   │
7. FINAL ──────────► ✓ Infrastructure prête !
                   
                   USER accède :
                   http://localhost/adminer/adminer.php
                       │
                       ├─ Adminer PHP (for-target-1)
                       │
                       └─ MySQL 8.0 (for-target-3)
```

---

## 🔍 Points clés de l'architecture

1. **Isolation réseau** : Tous les conteneurs sur un réseau bridge isolé
2. **Communication interne** : DNS Docker (nom d'hôte = service_name)
3. **Sécurité SSH** : Clés SSH montées en volume
4. **Gestion des secrets** : Ansible Vault pour les passwords
5. **Orchestration** : 3 playbooks séquentiels coordonnés
6. **Idempotence** : Playbooks exécutables plusieurs fois
7. **Traçabilité** : Logs détaillés pour debug

---

## 📚 Technologies utilisées

| Technologie | Version | Rôle |
|---|---|---|
| Docker | 24.x | Conteneurisation |
| Docker Compose | 2.x | Orchestration Docker |
| Ansible | 2.10+ | Orchestration Infrastructure |
| Apache2 | 2.4 | Serveur Web |
| PHP | 8.2 | Exécution scripts |
| Adminer | 4.8.1 | Interface Web BD |
| MySQL | 8.0 | Base de données |
| Ubuntu | 22.04 LTS | OS conteneurs |

---

## 💡 Prochaines étapes possibles

1. **Port Mapping** : Exposer les ports sur l'hôte
2. **SSL/TLS** : Ajouter certificats HTTPS
3. **Backup** : Automatiser backups MySQL
4. **Monitoring** : Ajouter monitoring/alertes
5. **HA/Clustering** : Multiple instances web
6. **Métriques** : Prometheus/Grafana
7. **CI/CD** : Pipeline GitHub Actions

---

## 📞 Support et Debugging



Voir `Makefile` pour :
- Commandes raccourcies
- Tests automatisés
- Opérations courantes

---

**Fin de l'Architecture - Document complet ! 🎉**
