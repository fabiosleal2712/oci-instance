# 🚀 Oracle Cloud ARM Instance - Automação com OpenTofu + Jenkins

Projeto para criar automaticamente instâncias ARM Always Free na Oracle Cloud usando OpenTofu/Terraform e Jenkins com sistema de retry inteligente.

## 📁 Estrutura do Projeto

```
oci-instance/
├── main.tf                    # Configuração OpenTofu/Terraform
├── Jenkinsfile                # Pipeline Jenkins com retry
├── setup_instructions.md      # Guia completo de configuração
├── README.md                  # Este arquivo
└── .gitignore                 # Arquivos a ignorar no Git
```

## ✅ Pré-requisitos

- ✅ Jenkins instalado e rodando
- ✅ OpenTofu v1.10.7 instalado
- ✅ OCI CLI v3.70.1 instalado
- [ ] Oracle Cloud Account (Always Free Tier)
- [ ] API Keys configuradas na Oracle Cloud
- [ ] Credentials configuradas no Jenkins

## 🚀 Quick Start

### 1. Configure as API Keys da Oracle Cloud

Siga as instruções detalhadas em [`setup_instructions.md`](setup_instructions.md) seção "Configuração da API Oracle".

### 2. Adicione as Credentials no Jenkins

Vá em `Jenkins → Manage Jenkins → Credentials → System → Global credentials` e adicione:

**Secret Text:**
- `oracle-tenancy-ocid`
- `oracle-user-ocid`
- `oracle-fingerprint`
- `oracle-compartment-ocid`
- `oracle-ssh-public-key`

**Secret File:**
- `oracle-private-key-file` (arquivo `.pem` da API)

### 3. Crie o Job no Jenkins

1. Jenkins → New Item → Pipeline
2. Nome: `Oracle-ARM-Retry`
3. Marque: "This project is parameterized"
4. Em "Pipeline Definition": escolha "Pipeline script from SCM"
5. Configure o repositório Git apontando para este projeto
6. Salve

### 4. Execute o Pipeline

1. Vá em `Oracle-ARM-Retry → Build with Parameters`
2. Configure os parâmetros:
   - **MAX_ATTEMPTS**: `1000` (ou `0` para infinito)
   - **WAIT_BETWEEN_ATTEMPTS**: `60` segundos
   - **OCPU_COUNT**: `4`
   - **MEMORY_GB**: `24`
   - **BOOT_VOLUME_GB**: `200`
   - **REGION**: `us-ashburn-1`
3. Clique em "Build"

## 📊 Monitoramento

O pipeline mostrará em tempo real:
- 🔄 Número da tentativa atual
- ⏱️ Tempo decorrido
- ✅ Status de cada tentativa
- 📡 IP público quando conseguir criar

## 🎯 Estratégias de Uso

### Deixar rodando continuamente
```
MAX_ATTEMPTS = 0 (infinito)
WAIT_BETWEEN_ATTEMPTS = 60
```

### Tentar em horários específicos
Configure um Cron no Jenkins:
```
# Todo dia às 3h da manhã
H 3 * * *
```

### Múltiplas tentativas rápidas
```
MAX_ATTEMPTS = 100
WAIT_BETWEEN_ATTEMPTS = 30
```

## 🔧 Comandos Úteis

### Testar OpenTofu localmente

```bash
# Inicializar
tofu init

# Validar configuração
tofu validate

# Ver plano
tofu plan

# Aplicar (criar recursos)
tofu apply

# Destruir recursos
tofu destroy
```

### Verificar instalação do OpenTofu

```bash
tofu version
```

## 📝 Variáveis de Ambiente

O pipeline usa as seguintes variáveis (injetadas via Jenkins Credentials):

- `TF_VAR_tenancy_ocid` - OCID do Tenancy
- `TF_VAR_user_ocid` - OCID do User
- `TF_VAR_fingerprint` - Fingerprint da API Key
- `TF_VAR_compartment_ocid` - OCID do Compartment
- `TF_VAR_ssh_public_key` - Chave SSH pública
- `TF_VAR_private_key_path` - Caminho da chave privada
- `TF_VAR_region` - Região da Oracle Cloud
- `TF_VAR_ocpu_count` - Número de OCPUs
- `TF_VAR_memory_gb` - Memória em GB
- `TF_VAR_boot_volume_gb` - Tamanho do disco

## 🐛 Troubleshooting

### Erro: "Authentication failed"
- Verifique as credentials no Jenkins
- Confirme que o fingerprint está correto
- Teste a API Key manualmente

### Erro: "Out of capacity" persistente
- Continue tentando (pode levar dias)
- Tente horários alternativos (madrugada)
- Reduza recursos temporariamente (2 OCPU)

### Erro: "Service limits exceeded"
- Verifique se já tem instâncias ARM criadas
- Limite Always Free: 4 OCPUs total
- Delete instâncias antigas se necessário

### Terraform state lock
```bash
cd /var/lib/jenkins/workspace/Oracle-ARM-Retry/
rm -f .terraform.tfstate.lock.info
```

## 📚 Documentação

- [Setup Instructions](setup_instructions.md) - Guia completo passo a passo
- [Next Steps](NEXT_STEPS.md) - Guia rápido dos próximos passos
- [OCI CLI Setup](OCI_CLI_SETUP.md) - Configuração do Oracle Cloud CLI
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Oracle Cloud Infrastructure Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

## 🎉 Após Conseguir a VM

```bash
# Conectar
ssh -i ~/.ssh/oracle_vm_key ubuntu@<IP_PUBLICO>

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker (opcional)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Configurar firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 📞 Suporte

Para problemas ou dúvidas:

1. Consulte [`setup_instructions.md`](setup_instructions.md)
2. Verifique os logs do Jenkins
3. Teste o OpenTofu manualmente
4. Confirme as credentials na Oracle Cloud

## 📄 Licença

Este projeto é fornecido "como está" para uso pessoal.

---

**Boa sorte! 🍀 Com persistência você consegue a VM ARM!**

*Última atualização: Novembro 2025*
# oci-instance
