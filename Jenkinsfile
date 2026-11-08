// Phase 1: test-only job on any branch. Deploy targets (web | patch |
// release | db) arrive in Phase 3 with tools/build_all.sh.
pipeline {
  agent any
  options {
    disableConcurrentBuilds()
    timestamps()
  }
  parameters {
    gitParameter name: 'BRANCH', type: 'PT_BRANCH', defaultValue: 'main',
      branchFilter: 'origin/(.*)', selectedValue: 'DEFAULT'
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
  }
}
