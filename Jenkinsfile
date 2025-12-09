pipeline {
	agent any

	options {
		timestamps()
	}

	parameters {
		string(
			name: 'REMOTE_HOST',
			defaultValue: 'fabioleal@10.30.0.50',
			description: 'Host SSH que contém a pasta do projeto'
		)
		string(
			name: 'REMOTE_WORKDIR',
			defaultValue: '/home/fabioleal/.oci-instancias/oci-instance',
			description: 'Diretório remoto com o repositório'
		)
		string(
			name: 'GIT_BRANCH',
			defaultValue: 'main',
			description: 'Branch que será usada no git pull'
		)
		string(
			name: 'REMOTE_APPLY_COMMAND',
			defaultValue: 'terradorm apply --aprove',
			description: 'Comando remoto executado após o git pull'
		)
		string(
			name: 'REMOTE_SSH_CREDENTIAL_ID',
			defaultValue: '8d28c532-531f-4307-a95e-f4c615fde2f3',
			description: 'Credencial "SSH Username with private key" configurada no Jenkins'
		)
	}

	stages {
		stage('Remote Apply') {
			steps {
				script {
					echo "🌐 Conectando em ${params.REMOTE_HOST}"
				}
				sshagent(credentials: [params.REMOTE_SSH_CREDENTIAL_ID]) {
					sh """
						ssh -o StrictHostKeyChecking=no ${params.REMOTE_HOST} <<REMOTE_EOF
						set -euo pipefail
						cd \"${params.REMOTE_WORKDIR}\"
						git fetch --all --prune
						git checkout \"${params.GIT_BRANCH}\"
						git pull --rebase origin \"${params.GIT_BRANCH}\"
						${params.REMOTE_APPLY_COMMAND}
						REMOTE_EOF
					"""
				}
			}
		}
	}

	post {
		success {
			echo "✅ Deploy remoto concluído"
		}
		failure {
			echo "❌ Falha ao executar os comandos remotos"
		}
	}
}
