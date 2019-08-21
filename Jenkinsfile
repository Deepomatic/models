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
    }
}
