#!/usr/bin/env bash
#
# run-tests.sh — Execute les tests unitaires du back-end et du front-end
# en detectant automatiquement le type de projet, et genere des rapports
# JUnit XML consolides dans le repertoire test-results/.
#
# Usage : ./run-tests.sh
#
# Codes de sortie :
#   0 = tous les tests ont reussi
#   1 = au moins un projet a echoue (build ou tests)

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${ROOT_DIR}/test-results"
BACK_DIR="${ROOT_DIR}/back"
FRONT_DIR="${ROOT_DIR}/front"

GLOBAL_EXIT_CODE=0

log() {
    echo "[run-tests] $1"
}

error() {
    echo "[run-tests][ERREUR] $1" >&2
}

# ---------------------------------------------------------------------------
# 1. Nettoyage des artefacts de tests precedents
# ---------------------------------------------------------------------------
log "Nettoyage du repertoire ${RESULTS_DIR}"
rm -rf "${RESULTS_DIR}"
mkdir -p "${RESULTS_DIR}/back" "${RESULTS_DIR}/front"

# ---------------------------------------------------------------------------
# 2. Back-end (detection Gradle / Maven)
# ---------------------------------------------------------------------------
run_backend_tests() {
    if [ ! -d "${BACK_DIR}" ]; then
        log "Aucun dossier back/ trouve, back-end ignore."
        return 0
    fi

    if [ -f "${BACK_DIR}/build.gradle" ] || [ -f "${BACK_DIR}/build.gradle.kts" ]; then
        log "Back-end detecte : Gradle"

        if [ ! -f "${BACK_DIR}/gradlew" ]; then
            error "gradlew introuvable dans ${BACK_DIR}. Verifiez la presence du Gradle Wrapper."
            return 1
        fi

        chmod +x "${BACK_DIR}/gradlew"

        log "Execution des tests back-end (Gradle)..."
        (cd "${BACK_DIR}" && ./gradlew test)
        local exit_code=$?

        if [ -d "${BACK_DIR}/build/test-results/test" ]; then
            cp "${BACK_DIR}"/build/test-results/test/*.xml "${RESULTS_DIR}/back/" 2>/dev/null
            log "Rapports JUnit back-end copies dans ${RESULTS_DIR}/back/"
        else
            error "Aucun rapport de test trouve pour le back-end."
        fi

        return ${exit_code}

    elif [ -f "${BACK_DIR}/pom.xml" ]; then
        log "Back-end detecte : Maven"

        log "Execution des tests back-end (Maven)..."
        (cd "${BACK_DIR}" && ./mvnw test)
        local exit_code=$?

        if [ -d "${BACK_DIR}/target/surefire-reports" ]; then
            cp "${BACK_DIR}"/target/surefire-reports/*.xml "${RESULTS_DIR}/back/" 2>/dev/null
            log "Rapports JUnit back-end copies dans ${RESULTS_DIR}/back/"
        else
            error "Aucun rapport de test trouve pour le back-end."
        fi

        return ${exit_code}
    else
        error "Type de projet back-end non reconnu (ni build.gradle, ni pom.xml)."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# 3. Front-end (detection npm)
# ---------------------------------------------------------------------------
run_frontend_tests() {
    if [ ! -d "${FRONT_DIR}" ]; then
        log "Aucun dossier front/ trouve, front-end ignore."
        return 0
    fi

    if [ ! -f "${FRONT_DIR}/package.json" ]; then
        error "Type de projet front-end non reconnu (package.json introuvable)."
        return 1
    fi

    log "Front-end detecte : npm"

    if [ ! -d "${FRONT_DIR}/node_modules" ]; then
        log "Dependances manquantes, execution de npm ci..."
        (cd "${FRONT_DIR}" && npm ci)
        if [ $? -ne 0 ]; then
            error "Echec de npm ci pour le front-end."
            return 1
        fi
    fi

    log "Execution des tests front-end (Karma/Angular)..."
    (cd "${FRONT_DIR}" && npx ng test --watch=false --browsers=ChromeHeadlessNoSandbox --code-coverage)
    local exit_code=$?

    if [ -f "${ROOT_DIR}/test-results/front/junit.xml" ]; then
        log "Rapport JUnit front-end deja present dans ${RESULTS_DIR}/front/"
    else
        error "Aucun rapport de test trouve pour le front-end (verifier junitReporter dans karma.conf.js)."
    fi

    return ${exit_code}
}

# ---------------------------------------------------------------------------
# 4. Execution
# ---------------------------------------------------------------------------
log "=== Debut de l'execution des tests ==="

run_backend_tests
BACK_EXIT=$?
if [ ${BACK_EXIT} -ne 0 ]; then
    error "Les tests back-end ont echoue (code ${BACK_EXIT})."
    GLOBAL_EXIT_CODE=1
else
    log "Tests back-end : OK"
fi

run_frontend_tests
FRONT_EXIT=$?
if [ ${FRONT_EXIT} -ne 0 ]; then
    error "Les tests front-end ont echoue (code ${FRONT_EXIT})."
    GLOBAL_EXIT_CODE=1
else
    log "Tests front-end : OK"
fi

log "=== Fin de l'execution des tests ==="
log "Rapports disponibles dans : ${RESULTS_DIR}"

exit ${GLOBAL_EXIT_CODE}