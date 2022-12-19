pipeline{
	agent any

	environment {
		DOCKERHUB_CREDENTIALS=credentials('dockerhub-cred-fdm')
	}

	stages {

		stage('Build') {

			steps {
				sh 'docker build -t eaglehaslanded/fdm:latest .'
			}
		}

		stage('Login') {

			steps {
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
			}
		}

		stage('Push') {

			steps {
				sh 'docker push eaglehaslanded/fdm:latest'
			}
		}
	}
	post {
		always {
			sh 'docker logout'
		}
	}
}