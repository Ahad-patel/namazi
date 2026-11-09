// One-click deploy on the dev Mac. Every run: checkout BRANCH → check.sh →
// TARGET. `db` is never part of `all`, and ENV=prod db stops for a typed
// "PROD" confirmation.
//
// Credentials (Jenkins → Credentials):
//   masjid-env-staging, masjid-env-prod   secret file: env.<env>.json
//   masjid-android-keystore               secret file: upload .jks
//   masjid-android-key-properties         secret file: key.properties
//                                         (storeFile=/tmp/... is rewritten below)
//   shorebird-token                       secret text: SHOREBIRD_TOKEN
//   vercel-token                          secret text: VERCEL_TOKEN
//   supabase-access-token-<env>           secret text: SUPABASE_ACCESS_TOKEN
//   supabase-db-password-<env>            secret text: SUPABASE_DB_PASSWORD
//   supabase-project-ref-<env>            secret text: project ref for `supabase link`
pipeline {
  agent any
  options {
    disableConcurrentBuilds()
    timestamps()
  }
  parameters {
    gitParameter name: 'BRANCH', type: 'PT_BRANCH', defaultValue: 'main',
      branchFilter: 'origin/(.*)', selectedValue: 'DEFAULT'
    choice name: 'TARGET', choices: ['all', 'web', 'patch', 'release', 'db', 'check'],
      description: 'all = web + patch. db = migrations + verify_remote (never part of all). check = tests only.'
    choice name: 'ENV', choices: ['staging', 'prod'], description: 'Which Supabase project / env file.'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scmGit(branches: [[name: "*/${params.BRANCH}"]],
          userRemoteConfigs: scm.userRemoteConfigs)
      }
    }
    stage('Check') {
      steps {
        sh './tools/check.sh'
      }
    }
    stage('Confirm prod db') {
      when { expression { params.TARGET == 'db' && params.ENV == 'prod' } }
      steps {
        script {
          def typed = input message: 'Apply migrations to PROD?',
            parameters: [string(name: 'CONFIRM', description: 'Type PROD to continue')]
          if (typed != 'PROD') { error('Not confirmed; nothing applied.') }
        }
      }
    }
    stage('Deploy') {
      when { expression { params.TARGET != 'check' } }
      steps {
        withCredentials([
          file(credentialsId: "masjid-env-${params.ENV}", variable: 'ENV_FILE'),
        ]) {
          script {
            // env.json and key files are removed by the trap even on failure.
            def prelude = '''#!/bin/bash
              set -euo pipefail
              trap 'rm -f env.json android/key.properties android/upload.jks' EXIT
              cp "$ENV_FILE" env.json
            '''
            switch (params.TARGET) {
              case 'web':
                withCredentials([string(credentialsId: 'vercel-token', variable: 'VERCEL_TOKEN')]) {
                  sh prelude + './tools/build_all.sh web'
                }
                break
              case 'patch':
              case 'all':
                withCredentials([
                  string(credentialsId: 'shorebird-token', variable: 'SHOREBIRD_TOKEN'),
                  string(credentialsId: 'vercel-token', variable: 'VERCEL_TOKEN'),
                ]) {
                  sh prelude + "./tools/build_all.sh ${params.TARGET}"
                }
                break
              case 'release':
                withCredentials([
                  string(credentialsId: 'shorebird-token', variable: 'SHOREBIRD_TOKEN'),
                  file(credentialsId: 'masjid-android-keystore', variable: 'KEYSTORE'),
                  file(credentialsId: 'masjid-android-key-properties', variable: 'KEYPROPS'),
                ]) {
                  sh prelude + '''
                    cp "$KEYSTORE" android/upload.jks
                    sed -E "s|^storeFile=.*|storeFile=$PWD/android/upload.jks|" "$KEYPROPS" > android/key.properties
                    ./tools/build_all.sh release
                  '''
                }
                break
              case 'db':
                withCredentials([
                  string(credentialsId: "supabase-access-token-${params.ENV}", variable: 'SUPABASE_ACCESS_TOKEN'),
                  string(credentialsId: "supabase-db-password-${params.ENV}", variable: 'SUPABASE_DB_PASSWORD'),
                  string(credentialsId: "supabase-project-ref-${params.ENV}", variable: 'PROJECT_REF'),
                ]) {
                  sh prelude + '''
                    supabase link --project-ref "$PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
                    supabase db push --password "$SUPABASE_DB_PASSWORD"
                    supabase functions deploy delete-account --project-ref "$PROJECT_REF"
                    supabase functions deploy purge-claims --no-verify-jwt --project-ref "$PROJECT_REF"
                    ./tools/verify_remote.sh
                  '''
                }
                break
            }
          }
        }
      }
    }
  }
  post {
    success {
      archiveArtifacts artifacts: 'dist/*.apk, dist/*.aab', allowEmptyArchive: true, fingerprint: true
    }
  }
}
