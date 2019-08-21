node {
    sshagent (credentials: (env.DMAKE_JENKINS_SSH_AGENT_CREDENTIALS ?
                            env.DMAKE_JENKINS_SSH_AGENT_CREDENTIALS : '').tokenize(',')) {
        if (params.CLEAR_WORKSPACE) {
            deleteDir()
        }
        checkout([$class: 'GitSCM',
                  branches: scm.branches,
                  extensions: scm.extensions + [[$class: 'SubmoduleOption', recursiveSubmodules: true]],
                  userRemoteConfigs: scm.userRemoteConfigs])

        docker.build 'models:${BUILD_TAG}'
        sh 'ls'
        docker.build('models_test:${BUILD_TAG}', "--build-arg BASE_IMAGE=models:${BUILD_TAG} -f Dockerfile.cmd .")
    }
}
