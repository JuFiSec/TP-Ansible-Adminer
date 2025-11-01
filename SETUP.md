# Installation - TP Ansible Adminer

## Prérequis système

- Docker Desktop 24.x+ ou Docker Engine
- Docker Compose 2.20+
- Ansible 2.14+
- Python 3.8+
- 8 GB RAM minimum
- 20 GB espace disque

## Installation des dépendances

### macOS
\`\`\`bash
brew install docker docker-compose ansible
\`\`\`

### Linux (Ubuntu/Debian)
\`\`\`bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose ansible
sudo usermod -aG docker $USER
\`\`\`

### Windows
- Télécharger Docker Desktop
- Installer Ansible via WSL2 ou Chocolatey

## Configuration du projet

### 1. Cloner le repository
\`\`\`bash
git clone https://github.com/JuFiSec/TP-Ansible-Adminer.git
cd TP-Ansible-Adminer
\`\`\`

### 2. Configurer les variables
\`\`\`bash
cp .env.example .env
# Éditer .env si besoin
\`\`\`

### 3. Vérifier les fichiers de configuration
\`\`\`bash
# Ansible
cat ansible.cfg
ls ansible-config/

# Docker
cat docker-compose.yml
ls .docker/
\`\`\`

## Démarrage

### Démarrer l'infrastructure
\`\`\`bash
docker-compose up -d
sleep 30
\`\`\`

### Vérifier la connectivité
\`\`\`bash
docker exec for-controller ansible -i /ansible/inventory.ini all -m ping
\`\`\`

### Lancer les playbooks
\`\`\`bash
docker exec for-controller ansible-playbook \\
  -i /ansible/inventory.ini \\
  /ansible/site.yml \\
  -v --ask-vault-pass

# Vault password: SecureVaultPassword2025!
\`\`\`

## Vérification

### Accéder à Adminer
- URL : http://localhost/adminer/adminer.php
- Serveur : db
- Utilisateur : adminer_user
- Mot de passe : AdminerUserPassword_Secure2025!

### Arrêter l'infrastructure
\`\`\`bash
docker-compose down
\`\`\`

### Nettoyer complètement
\`\`\`bash
docker-compose down -v
docker system prune -a
\`\`\`

## Variables d'environnement (.env)

\`\`\`bash
# Docker
COMPOSE_PROJECT_NAME=tp-ansible-adminer
DOCKER_NETWORK=infra

# Ansible
ANSIBLE_INVENTORY=ansible-config/inventory.ini
ANSIBLE_CONFIG=ansible-config/ansible.cfg

# MySQL
MYSQL_ROOT_PASSWORD=RootPasswordMySQL8_0_Secure2025!
MYSQL_ADMINER_PASSWORD=AdminerUserPassword_Secure2025!

# Vault
ANSIBLE_VAULT_PASSWORD_FILE=ansible-config/.vault-password
\`\`\`

## Troubleshooting

Pour les erreurs courantes, voir [TROUBLESHOOTING.md](TROUBLESHOOTING.md)