pipeline {
    agent any
    
    parameters {
        string(
            name: 'MAX_ATTEMPTS',
            defaultValue: '1000',
            description: 'Número máximo de tentativas (0 = infinito)'
        )
        string(
            name: 'WAIT_BETWEEN_ATTEMPTS',
            defaultValue: '60',
            description: 'Tempo de espera entre tentativas (segundos)'
        )
        string(
            name: 'OCPU_COUNT',
            defaultValue: '4',
            description: 'Número de OCPUs (Always Free: até 4)'
        )
        string(
            name: 'MEMORY_GB',
            defaultValue: '24',
            description: 'Memória em GB (Always Free: até 24)'
        )
        string(
            name: 'BOOT_VOLUME_GB',
            defaultValue: '200',
            description: 'Tamanho do disco em GB (Always Free: até 200)'
        )
        string(
            name: 'REGION',
            defaultValue: 'us-ashburn-1',
            description: 'Região da Oracle Cloud'
        )
        string(
            name: 'TRY_ALL_ADS',
            defaultValue: '2',
            description: 'Tentar em quantos ADs (0=apenas AD-1, 1=AD-1 e AD-2, 2=todos os 3 ADs)'
        )
    }
    
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "🚀 ORACLE CLOUD ARM - RETRY AUTOMATION"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "📋 Configurações:"
                    echo "   • Max tentativas: ${params.MAX_ATTEMPTS}"
                    echo "   • Intervalo: ${params.WAIT_BETWEEN_ATTEMPTS}s"
                    echo "   • OCPUs: ${params.OCPU_COUNT}"
                    echo "   • Memória: ${params.MEMORY_GB} GB"
                    echo "   • Disco: ${params.BOOT_VOLUME_GB} GB"
                    echo "   • Região: ${params.REGION}"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                }
            }
        }
        
        stage('Initialize Terraform') {
            steps {
                script {
                    echo "🔧 Inicializando OpenTofu/Terraform..."
                    
                    // Verifica se tofu está disponível, senão usa terraform
                    def tfCmd = sh(
                        script: 'command -v tofu >/dev/null 2>&1 && echo "tofu" || echo "terraform"',
                        returnStdout: true
                    ).trim()
                    
                    env.TF_CMD = tfCmd
                    echo "✅ Usando: ${tfCmd}"
                    
                    sh "${tfCmd} init -upgrade"
                }
            }
        }
        
        stage('Retry Loop') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'oracle-tenancy-ocid', variable: 'TF_VAR_tenancy_ocid'),
                        string(credentialsId: 'oracle-user-ocid', variable: 'TF_VAR_user_ocid'),
                        string(credentialsId: 'oracle-fingerprint', variable: 'TF_VAR_fingerprint'),
                        string(credentialsId: 'oracle-compartment-ocid', variable: 'TF_VAR_compartment_ocid'),
                        string(credentialsId: 'oracle-ssh-public-key', variable: 'TF_VAR_ssh_public_key'),
                        file(credentialsId: 'oracle-private-key-file', variable: 'PRIVATE_KEY_FILE')
                    ]) {
                        env.TF_VAR_private_key_path = env.PRIVATE_KEY_FILE
                        env.TF_VAR_region = params.REGION
                        env.TF_VAR_ocpu_count = params.OCPU_COUNT
                        env.TF_VAR_memory_gb = params.MEMORY_GB
                        env.TF_VAR_boot_volume_gb = params.BOOT_VOLUME_GB
                        env.TF_VAR_try_all_ads = params.TRY_ALL_ADS
                        
                        def maxAttempts = params.MAX_ATTEMPTS.toInteger()
                        def waitTime = params.WAIT_BETWEEN_ATTEMPTS.toInteger()
                        def attempt = 0
                        def success = false
                        def startTime = System.currentTimeMillis()
                        
                        while (!success && (maxAttempts == 0 || attempt < maxAttempts)) {
                            attempt++
                            def elapsedMinutes = ((System.currentTimeMillis() - startTime) / 60000).round(1)
                            
                            echo ""
                            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                            echo "🔄 TENTATIVA #${attempt} (${elapsedMinutes} minutos decorridos)"
                            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                            
                            try {
                                // Tenta aplicar a configuração
                                sh "${env.TF_CMD} apply -auto-approve"
                                
                                // Se chegou aqui, deu certo!
                                success = true
                                
                                echo ""
                                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                                echo "✅ SUCESSO! Instância criada com sucesso!"
                                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                                echo "📊 Estatísticas:"
                                echo "   • Tentativas: ${attempt}"
                                echo "   • Tempo total: ${elapsedMinutes} minutos"
                                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                                
                                // Captura os outputs (agora são arrays)
                                def publicIps = sh(
                                    script: "${env.TF_CMD} output -json public_ips",
                                    returnStdout: true
                                ).trim()
                                
                                def instanceIds = sh(
                                    script: "${env.TF_CMD} output -json instance_ids",
                                    returnStdout: true
                                ).trim()
                                
                                def sshCommands = sh(
                                    script: "${env.TF_CMD} output -json ssh_commands",
                                    returnStdout: true
                                ).trim()
                                
                                def availabilityDomains = sh(
                                    script: "${env.TF_CMD} output -json availability_domains",
                                    returnStdout: true
                                ).trim()
                                
                                echo ""
                                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                                echo "🎉 INSTÂNCIAS CRIADAS COM SUCESSO!"
                                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                                echo ""
                                echo "📡 IPs Públicos: ${publicIps}"
                                echo ""
                                echo "🔑 Comandos SSH: ${sshCommands}"
                                echo ""
                                echo "💾 IDs das Instâncias: ${instanceIds}"
                                echo ""
                                echo "🌍 Availability Domains: ${availabilityDomains}"
                                echo ""
                                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                                
                                // Salva as informações para uso posterior
                                env.PUBLIC_IPS = publicIps
                                env.INSTANCE_IDS = instanceIds
                                env.SSH_COMMANDS = sshCommands
                                
                            } catch (Exception e) {
                                echo "❌ Tentativa #${attempt} falhou"
                                
                                def errorMsg = e.getMessage()
                                
                                // Verifica se é erro de capacidade
                                if (errorMsg.contains("Out of host capacity") || 
                                    errorMsg.contains("InternalError") ||
                                    errorMsg.contains("500")) {
                                    echo "⚠️  Erro de capacidade detectado"
                                } else {
                                    echo "⚠️  Erro: ${errorMsg.take(200)}"
                                }
                                
                                // Se não for a última tentativa, aguarda
                                if (maxAttempts == 0 || attempt < maxAttempts) {
                                    echo "⏳ Aguardando ${waitTime}s antes da próxima tentativa..."
                                    sleep(waitTime)
                                    
                                    // Limpa o state lock se existir
                                    sh "rm -f .terraform.tfstate.lock.info || true"
                                } else {
                                    echo "❌ Número máximo de tentativas atingido"
                                    error("Falha após ${attempt} tentativas")
                                }
                            }
                        }
                        
                        if (!success) {
                            error("Não foi possível criar a instância após ${attempt} tentativas")
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "✅ PIPELINE CONCLUÍDO COM SUCESSO!"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "🎯 Próximos passos:"
                echo "   1. Conecte via SSH usando os comandos mostrados acima"
                echo "   2. Atualize o sistema: sudo apt update && sudo apt upgrade -y"
                echo "   3. Configure o firewall conforme necessário"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            }
        }
        
        failure {
            script {
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "❌ PIPELINE FALHOU"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "🔍 Verifique:"
                echo "   • Credentials do Jenkins"
                echo "   • Limites de serviço na Oracle Cloud"
                echo "   • Logs detalhados acima"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            }
        }
        
        always {
            script {
                // Limpa arquivos temporários
                sh "rm -f .terraform.tfstate.lock.info || true"
            }
        }
    }
}
