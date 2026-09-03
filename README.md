# MicroCRM — Orion

Application de démonstration type CRM (Customer Relationship Management) qui permet la gestion de clients et d'organisations. 

- **Back-end** : Java 17 / Spring Boot 3 (Gradle)
- **Front-end** : Angular 17

## Sommaire

- Démarrer en local
- Lancer les tests
- Utiliser Docker
- Pipeline CI/CD
- Monitoring (ELK)
- Publier une release
- Points à savoir

---

## Démarrer en local

### Back-end

```bash
cd back
./gradlew build          # Windows : gradlew.bat build
java -jar build/libs/microcrm-0.0.1-SNAPSHOT.jar
```
> API disponible sur **http://localhost:8080**

### Front-end

```bash
cd front
npm install     # seulement la première fois
npx ng serve 
```

>  Application disponible sur **http://localhost:4200**

> La base de données (HSQLDB) tourne **en mémoire** : toutes les données créées sont perdues à chaque redémarrage. Un jeu de données de démo est rechargé automatiquement.

---

## Lancer les tests

Un script à la racine lance automatiquement les tests des deux projets et génère des rapports dans `test-results/` :

```bash
./run-tests.sh
```

Ou manuellement :

```bash
cd back 
./gradlew test

cd front 
npx ng test --watch=false --browsers=ChromeHeadlessNoSandbox
```

---

## Utiliser Docker

### Lancer tout le projet d'un coup (recommandé)

```bash
docker compose up --build
```

Front sur **https://localhost**, API sur **http://localhost:8080**

### Construire une image seule

```bash
docker build --target back -t microcrm-back .
docker build --target front -t microcrm-front .
```

---

## Pipeline CI/CD

À chaque `push` sur GitHub, un workflow (`.github/workflows/ci.yml`) s'exécute automatiquement :

1. **Build + tests** du back-end et du front-end
2. **Analyse qualité** avec SonarQube Cloud
3. **Publication des images Docker** sur GitHub Container Registry (uniquement quand le code est fusionné sur `main`)

On développe toujours sur la branche `dev`, puis on fusionne vers `main` via une Pull Request une fois que tout est validé.

---

## Monitoring (ELK)

Une stack Elasticsearch/Logstash/Kibana permet de visualiser les logs de l'application en local. Elle est séparée du reste (pas utilisée en CI, trop lourde).

```bash
# 1. Démarrer ELK en premier
docker compose -f docker-compose-elk.yml up -d

# 2. Puis démarrer l'application
docker compose up --build
```

 Dashboard Kibana sur **http://localhost:5601**

> Nécessite environ 4 Go de RAM libres.

---

## Publier une release

Pour créer une version officielle (JAR + build Angular + changelog automatique) :

```bash
git tag v1.0.0
git push origin v1.0.0
```

Le tag doit suivre le format `vMAJEUR.MINEUR.CORRECTIF` (ex. `v1.2.0`).

---

## Points à savoir

- Les données ne sont **pas persistées** (base en mémoire) — normal, pas un bug.
- Le conteneur front tourne en `root` (nécessaire pour les ports 80/443), le back en utilisateur non-root.
- Les logs du front-end ne sont pas encore envoyés vers ELK (seul le back-end l'est).

Pour plus de détails (métriques, analyse de sécurité, choix techniques justifiés), voir le document **Documentation technique finale**.
