# ====================================================================
# MAKEFILE - COMMANDES POUR LE PROJET TP ANSIBLE ADMINER
# ====================================================================
# Utilisation : make <commande>
# Exemple : make up, make playbook, make down, etc.
# ====================================================================

.PHONY: help up down logs playbook init deploy adminer db clean vault

# ====================================================================
# VARIABLES
# ====================================================================

DOCKER_COMPOSE := docker-compose
ANSIBLE_PLAYBOOK := ansible-playbook
DOCKER := docker

# Couleurs pour l'affichage
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# ====================================================================
# COMMANDES DE BASE
# ====================================================================

help: ## Afficher l'aide
	@echo "$(BLUE)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         COMMANDES DISPONIBLES - TP ANSIBLE ADMINER    ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)DOCKER COMPOSE :$(NC)"
	@echo "  make up                 Démarrer tous les conteneurs"
	@echo "  make down               Arrêter tous les conteneurs"
	@echo "  make logs               Afficher les logs"
	@echo "  make ps                 Lister les conteneurs"
	@echo "  make clean              Nettoyer (supprimer les conteneurs)"
	@echo ""
	@echo "$(GREEN)ANSIBLE :$(NC)"
	@echo "  make playbook           Lancer site.yml (orchestration complète)"
	@echo "  make init               Lancer 01-init-servers.yml"
	@echo "  make adminer            Lancer 02-deploy-adminer.yml"
	@echo "  make db                 Lancer 03-deploy-database.yml"
	@echo "  make test               Tester la connectivité"
	@echo ""
	@echo "$(GREEN)VAULT :$(NC)"
	@echo "  make vault-encrypt      Chiffrer vault/secrets.yml"
	@echo "  make vault-decrypt      Déchiffrer vault/secrets.yml (édition)"
	@echo "  make vault-view         Afficher vault/secrets.yml en clair"
	@echo ""
	@echo "$(GREEN)UTILITAIRES :$(NC)"
	@echo "  make help               Afficher cette aide"
	@echo "  make status             Afficher le statut du projet"
	@echo ""

# ====================================================================
# DOCKER COMPOSE
# ====================================================================

up: ## Démarrer tous les conteneurs Docker
	@echo "$(YELLOW)[Docker] Démarrage des conteneurs...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✓ Conteneurs démarrés$(NC)"
	@$(MAKE) ps

down: ## Arrêter tous les conteneurs Docker
	@echo "$(YELLOW)[Docker] Arrêt des conteneurs...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Conteneurs arrêtés$(NC)"

logs: ## Afficher les logs des conteneurs
	@echo "$(YELLOW)[Docker] Logs en temps réel (Ctrl+C pour arrêter)...$(NC)"
	$(DOCKER_COMPOSE) logs -f

ps: ## Lister les conteneurs en cours d'exécution
	@echo "$(BLUE)État des conteneurs :$(NC)"
	$(DOCKER_COMPOSE) ps

clean: ## Nettoyer (supprimer les conteneurs et volumes)
	@echo "$(RED)[Docker] Suppression des conteneurs et volumes...$(NC)"
	$(DOCKER_COMPOSE) down -v
	@echo "$(GREEN)✓ Conteneurs et volumes supprimés$(NC)"

# ====================================================================
# ANSIBLE - PLAYBOOKS
# ====================================================================

playbook: up ## Lancer site.yml (orchestration complète)
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║          LANCEMENT PLAYBOOK COMPLET - site.yml        ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════╝$(NC)"
	@sleep 5
	$(DOCKER_COMPOSE) exec -T controller $(ANSIBLE_PLAYBOOK) site.yml -v

init: up ## Lancer 01-init-servers.yml
	@echo ""
	@echo "$(BLUE)📦 Lancement du playbook d'initialisation...$(NC)"
	$(DOCKER_COMPOSE) exec -T controller $(ANSIBLE_PLAYBOOK) 01-init-servers.yml -v

adminer: up ## Lancer 02-deploy-adminer.yml
	@echo ""
	@echo "$(BLUE)🌐 Lancement du playbook Adminer...$(NC)"
	$(DOCKER_COMPOSE) exec -T controller $(ANSIBLE_PLAYBOOK) 02-deploy-adminer.yml -v

db: up ## Lancer 03-deploy-database.yml
	@echo ""
	@echo "$(BLUE)🗄️  Lancement du playbook Database...$(NC)"
	$(DOCKER_COMPOSE) exec -T controller $(ANSIBLE_PLAYBOOK) 03-deploy-database.yml -v --ask-vault-pass

# ====================================================================
# VÉRIFICATIONS & TESTS
# ====================================================================

test: ## Tester la connectivité
	@echo "$(BLUE)🧪 Tests de connectivité...$(NC)"
	@echo ""
	@echo "$(YELLOW)[SSH] Vérifier la connexion SSH sur for-target-1...$(NC)"
	@$(DOCKER_COMPOSE) exec controller ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa ansible@for-target-1 "echo 'SSH OK'" || echo "$(RED)SSH ÉCHOUÉ$(NC)"
	@echo ""
	@echo "$(YELLOW)[SSH] Vérifier la connexion SSH sur for-target-3...$(NC)"
	@$(DOCKER_COMPOSE) exec controller ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa ansible@for-target-3 "echo 'SSH OK'" || echo "$(RED)SSH ÉCHOUÉ$(NC)"
	@echo ""
	@echo "$(YELLOW)[HTTP] Vérifier Apache sur for-target-1...$(NC)"
	@$(DOCKER_COMPOSE) exec controller curl -s http://for-target-1/ > /dev/null && echo "$(GREEN)✓ HTTP OK$(NC)" || echo "$(RED)HTTP ÉCHOUÉ$(NC)"
	@echo ""
	@echo "$(YELLOW)[MySQL] Vérifier MySQL sur for-target-3...$(NC)"
	@$(DOCKER_COMPOSE) exec controller nc -zv for-target-3 3306 2>&1 | grep -q succeeded && echo "$(GREEN)✓ MySQL OK$(NC)" || echo "$(RED)MySQL ÉCHOUÉ$(NC)"

status: ## Afficher le statut du projet
	@echo "$(BLUE)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                STATUT DU PROJET                       ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Conteneurs Docker :$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(YELLOW)Répertoires du projet :$(NC)"
	@ls -la | grep "^d" | grep -v "^\." | awk '{print "  " $$NF}'
	@echo ""
	@echo "$(YELLOW)Fichiers importants :$(NC)"
	@ls -lah docker-compose.yml ansible.cfg inventory.ini 2>/dev/null | awk '{print "  " $$NF " (" $$5 ")"}'
	@echo ""

# ====================================================================
# VAULT ANSIBLE
# ====================================================================

vault-encrypt: ## Chiffrer vault/secrets.yml
	@echo "$(YELLOW)🔐 Chiffrement de vault/secrets.yml...$(NC)"
	ansible-vault encrypt vault/secrets.yml || echo "$(YELLOW)Fichier déjà chiffré ou inexistant$(NC)"
	@echo "$(GREEN)✓ Fichier chiffré$(NC)"

vault-decrypt: ## Déchiffrer vault/secrets.yml pour édition
	@echo "$(YELLOW)🔓 Déchiffrement de vault/secrets.yml...$(NC)"
	ansible-vault decrypt vault/secrets.yml || echo "$(YELLOW)Fichier non chiffré$(NC)"
	@echo "$(GREEN)✓ Fichier déchiffré (attention : ne pas commiter en clair !)$(NC)"

vault-view: ## Afficher vault/secrets.yml en clair
	@echo "$(YELLOW)👁️  Affichage de vault/secrets.yml...$(NC)"
	ansible-vault view vault/secrets.yml

vault-edit: ## Éditer vault/secrets.yml
	@echo "$(YELLOW)✏️  Édition de vault/secrets.yml...$(NC)"
	ansible-vault edit vault/secrets.yml

# ====================================================================
# SSH DANS LES CONTENEURS
# ====================================================================

ssh-controller: ## SSH dans le conteneur contrôleur
	@echo "$(BLUE)Connexion SSH au contrôleur...$(NC)"
	$(DOCKER) exec -it for-controller bash

ssh-target-1: ## SSH dans le conteneur for-target-1
	@echo "$(BLUE)Connexion SSH à for-target-1...$(NC)"
	$(DOCKER) exec -it for-target-1 bash

ssh-target-3: ## SSH dans le conteneur for-target-3
	@echo "$(BLUE)Connexion SSH à for-target-3...$(NC)"
	$(DOCKER) exec -it for-target-3 bash

# ====================================================================
# COMMANDES AVANCÉES
# ====================================================================

rebuild: clean up ## Rebuild complet (clean + up)
	@echo "$(GREEN)✓ Rebuild complet terminé$(NC)"

full-deploy: up init adminer db ## Déploiement complet
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║              ✓ DÉPLOIEMENT COMPLET !                  ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "Adminer disponible à :"
	@echo "  http://localhost/adminer/adminer.php"
	@echo ""

# ====================================================================
# COMMANDES PAR DÉFAUT
# ====================================================================

.DEFAULT_GOAL := help
