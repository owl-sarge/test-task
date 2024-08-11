pipeline {

    agent any
    environment {
        ImageName = 'owlsarge/wcg'
        tag ='latest'
        Cluster_IP ='192.168.49.2'
    }
    options {
        timestamps ()
    }
    stages {
        stage('Checkout') {    options {
        timestamps ()
    }
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/dev']], userRemoteConfigs: [[url: 'https://github.com/owl-sarge/test-chellenge.git'  ]]])
            }
        }
        
        stage('Verifi Dockerfile') {
            steps {
                script {
                  sh 'docker run --rm -i hadolint/hadolint < Dockerfile '
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                  sh 'docker build -t ${ImageName}:${tag} .'
                }
            }
        }
        
        stage('Run Docker Image') {
            steps {
                script {
                  sh '''
                  docker run -d -ti -p 8888:8888 --name=wcg-test  ${ImageName}:latest
                  IP_CONTAINER=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "wcg-test")
                  curl -I http://$IP_CONTAINER:8888
                  docker container stop wcg-test && docker container rm wcg-test
                  '''
                }
            }
        }
        
        stage('Deploy Docker Image') {
            steps {
                script {
                 withCredentials([string(credentialsId: 'owlsarge', variable: 'dockerhubpwd')]) {
                    sh 'docker login -u owlsarge -p ${dockerhubpwd}'
                 }  
                 sh 'docker push ${ImageName}:${tag}'
                }
            }
        }
    
        stage('Deploy App on pre-production') {
            steps {
                script {
                    kubeconfig(credentialsId: 'my_kubernetes', serverUrl: 'https://192.168.49.2:8443') {
                        sh 'kubectl apply -n pre-production -f deployment.yml && kubectl apply -n pre-production -f service.yml'
                    }
                }    
            }
        }
        
        stage ('Test Deploy') {
            steps {
                script {
                    kubeconfig(credentialsId: 'my_kubernetes', serverUrl: 'https://192.168.49.2:8443') {
                        sh '''
                            kubectl get -n pre-production deployment wcg && kubectl get -n pre-production service wcg-service
                            export NODE_PORT="$(kubectl get -n pre-production services/wcg-service -o go-template='{{(index .spec.ports 0).nodePort}}')"
                            sleep 10 && curl -I http://${Cluster_IP}:$NODE_PORT
                        '''
                    }
                }
            }
        }
        
        stage('Deploy App on production') {
            steps {
                input message: 'Deploy on Production', ok: 'YES'
                script {
                    kubeconfig(credentialsId: 'my_kubernetes', serverUrl: 'https://192.168.49.2:8443') {
                        sh 'kubectl apply -n production -f deployment.yml && kubectl apply -n production -f service.yml'
                    }
                }    
            }
        }
        
        stage ('Remove the deployment from the pre-production') {
            steps {
                script {
                    kubeconfig(credentialsId: 'my_kubernetes', serverUrl: 'https://192.168.49.2:8443') {
                        sh 'kubectl delete -n pre-production -f service.yml && kubectl delete -n pre-production -f deployment.yml'
                    }    
                }
            }
        }
    }
}  