#!groovy

def tryStep(String message, Closure block, Closure tearDown = null) {
    try {
        block()
    }
    catch (Throwable t) {
        // slackSend message: "${env.JOB_NAME}: ${message} failure ${env.BUILD_URL}", channel: '#ci-channel', color: 'danger'

        throw t
    }
    finally {
        if (tearDown) {
            tearDown()
        }
    }
}


node {
    stage("Checkout") {
        checkout scm
    }

    stage("Build image") {
        tryStep "build", {
            docker.withRegistry('https://repo.data.amsterdam.nl','docker-registry') {
                def image = docker.build("datapunt/iiif:${env.BUILD_NUMBER}", "--build-arg http_proxy=http://10.240.2.1:8080 --build-arg https_proxy=http://10.240.2.1:8080 MAVEN_OPTS=-Dhttp.proxyHost=10.240.2.1 -Dhttp.proxyPort=8080 -Dhttp.nonProxyHosts=localhost|127.0.0.1 .")
                image.push()
            }
        }
    }
}

if (${env.BRANCH_NAME} == "master") {

    node {
        stage('Push acceptance image') {
            tryStep "image tagging", {
                docker.withRegistry('https://repo.data.amsterdam.nl','docker-registry') {
                    def image = docker.image("datapunt/iiif:${env.BUILD_NUMBER}")
                    image.pull()
                    image.push("acceptance")
                }
            }
        }
    }

    node {
        stage("Deploy to ACC") {
            tryStep "deployment", {
                build job: 'Subtask_Openstack_Playbook',
                    parameters: [
                        [$class: 'StringParameterValue', name: 'INVENTORY', value: 'acceptance'],
                        [$class: 'StringParameterValue', name: 'PLAYBOOK', value: 'deploy-iiif.yml'],
                ]
            }
        }
    }

    stage('Waiting for approval') {
        // slackSend channel: '#ci-channel', color: 'warning', message: 'IIIF is waiting for Production Release - please confirm'
        input "Deploy to Production?"
    }

    node {
        stage('Push production image') {
            tryStep "image tagging", {
               docker.withRegistry('https://repo.data.amsterdam.nl','docker-registry') {
                def image = docker.image("datapunt/iiif:${env.BUILD_NUMBER}")
                    image.pull()
                    image.push("production")
                    image.push("latest")
                }
            }
        }
    }

    node {
        stage("Deploy") {
            tryStep "deployment", {
                build job: 'Subtask_Openstack_Playbook',
                parameters: [
                    [$class: 'StringParameterValue', name: 'INVENTORY', value: 'production'],
                    [$class: 'StringParameterValue', name: 'PLAYBOOK', value: 'deploy-iiif.yml'],
                ]
            }
        }
    }
}
