# 🚀 Guia Completo - Oracle Cloud ARM com OpenTofu + Jenkins

Este guia te ajuda a configurar um sistema automatizado para criar instâncias ARM Always Free na Oracle Cloud usando OpenTofu/Terraform e Jenkins.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração da API Oracle](#configuração-da-api-oracle)
3. [Configuração do Jenkins](#configuração-do-jenkins)
4. [Execução](#execução)
5. [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

### Software Necessário

```bash
# 1. OpenTofu (ou Terraform)
# Download: https://opentofu.org/docs/intro/install/
wget https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_linux_amd64.zip
unzip tofu_1.6.0_linux_amd64.zip
sudo mv tofu /usr/local/bin/

# Ou Terraform
# Download: https://www.terraform.io/downloads
```

### Jenkins já instalado ✅
Você mencionou que já tem Jenkins rodando - perfeito!

---

## 🔑 Configuração da API Oracle

### Passo 1: Criar API Key na Oracle Cloud

1. **Login na Oracle Cloud Console**
   - Acesse: https://cloud.oracle.com

2. **Navegue até Profile**
   ```
   Canto superior direito → Ícone do usuário → "User Settings"
   ```

3. **Crie API Key**
   ```
   Menu lateral esquerdo → "API Keys" → "Add API Key"
   ```

4. **Gere o par de chaves**
   ```bash
   # No seu computador/servidor Jenkins:
   mkdir -p ~/.oci
   cd ~/.oci
   
   # Gera chave privada
   openssl genrsa -out oci_api_key.pem 2048
   
   # Gera chave pública
   openssl rsa -pubout -in oci_api_key.pem -out oci_api_key_public.pem
   
   # Permissões corretas
   chmod 600 oci_api_key.pem
   chmod 644 oci_api_key_public.pem
   
   # Mostra a chave pública para copiar
   cat oci_api_key_public.pem
   ```

5. **Adicione a chave pública na Oracle**
   - Cole o conteúdo de `oci_api_key_public.pem`
   - Clique em "Add"
   - **IMPORTANTE**: Copie o "Configuration File Preview" que aparece

### Passo 2: Coletar OCIDs Necessários

Você precisa destes valores (aparecem no "Configuration File Preview"):

```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaa...
fingerprint=aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99
tenancy=ocid1.tenancy.oc1..aaaaaaaa...
region=us-ashburn-1
key_file=~/.oci/oci_api_key.pem
```

**Também precisa do Compartment OCID:**
```
Menu hamburger → Identity & Security → Compartments
Copie o OCID do compartment "root" ou do que você usar
```

### Passo 3: Criar Chave SSH para VMs

```bash
# Gera par de chaves SSH para acessar as VMs
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oracle_vm_key -N ""

# A chave pública será usada nas VMs
cat ~/.ssh/oracle_vm_key.pub
```

---

## ⚙️ Configuração do Jenkins

### Passo 1: Instalar Plugins

No Jenkins, instale:
- Pipeline
- Credentials Binding Plugin
- Git Plugin (se for versionar o código)

### Passo 2: Adicionar Credentials

**Vá em: `Jenkins → Manage Jenkins → Credentials → System → Global credentials`**

Adicione as seguintes credentials (tipo "Secret text"):

| ID | Valor | Descrição |
|---|---|---|
| `oracle-tenancy-ocid` | `ocid1.tenancy.oc1..aaaaa...` | Tenancy OCID |
| `oracle-user-ocid` | `ocid1.user.oc1..aaaaa...` | User OCID |
| `oracle-fingerprint` | `aa:bb:cc:dd:...` | Fingerprint da API Key |
| `oracle-compartment-ocid` | `ocid1.compartment.oc1..aaaaa...` | Compartment OCID |
| `oracle-ssh-public-key` | `ssh-rsa AAAAB3N...` | Conteúdo de `~/.ssh/oracle_vm_key.pub` |

**E uma credential tipo "Secret file":**

| ID | Arquivo | Descrição |
|---|---|---|
| `oracle-private-key-file` | `~/.oci/oci_api_key.pem` | Chave privada da API |

### Passo 3: Criar Pipeline Job

1. **Criar novo Job**
   ```
   Jenkins → New Item → Pipeline → Nome: "Oracle-ARM-Retry"
   ```

2. **Configurar Pipeline**
   - Marque: "This project is parameterized"
   - Cole o código do Jenkinsfile (artifact 2)
   - Em "Pipeline Definition": escolha "Pipeline script"
   - Cole o script Groovy

3. **Ou usar Pipeline from SCM** (recomendado)
   - Coloque os arquivos em um repositório Git
   - Configure para buscar do Git

### Passo 4: Estrutura de Arquivos

No seu servidor Jenkins, crie a seguinte estrutura:

```
/var/lib/jenkins/workspace/Oracle-ARM-Retry/
├── main.tf              # Arquivo do artifact 1
├── Jenkinsfile          # Arquivo do artifact 2
├── terraform.tfvars     # (Opcional) Variáveis extras
└── .terraform/          # (Criado automaticamente)
```

---

## 🚀 Execução

### Passo 1: Primeira Execução

1. **Abra o Job no Jenkins**
   ```
   Jenkins → Oracle-ARM-Retry → Build with Parameters
   ```

2. **Configure os parâmetros:**
   - **MAX_ATTEMPTS**: `1000` (ou `0` para infinito)
   - **WAIT_BETWEEN_ATTEMPTS**: `60` segundos
   - **OCPU_COUNT**: `4`
   - **MEMORY_GB**: `24`
   - **BOOT_VOLUME_GB**: `200`

3. **Clique em "Build"**

### Passo 2: Monitorar Execução

O Jenkins vai:
- ✅ Inicializar OpenTofu/Terraform
- 🔄 Tentar criar a instância
- ⏳ Aguardar entre tentativas se falhar
- ✅ Parar quando conseguir
- 📧 Mostrar IP e comando SSH

**Console Output mostrará:**
```
🔄 TENTATIVA #1 (0.5 minutos decorridos)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Tentativa #1 falhou
⚠️  Erro de capacidade detectado
⏳ Aguardando 60s...

🔄 TENTATIVA #2 (1.5 minutos decorridos)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
...
```

### Passo 3: Quando Conseguir

Você verá:
```
✅ SUCESSO! Instância criada com sucesso!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 INSTÂNCIA CRIADA COM SUCESSO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📡 IP Público: 140.238.123.456

🔑 Comando SSH: ssh ubuntu@140.238.123.456

💾 ID da Instância: ocid1.instance.oc1...
```

### Passo 4: Conectar na VM

```bash
# Use a chave SSH que você criou
ssh -i ~/.ssh/oracle_vm_key ubuntu@<IP_PUBLICO>

# Primeira vez, aceite a fingerprint
# Pronto! Você está dentro da VM!
```

---

## 🎯 Estratégias de Uso

### Estratégia 1: Deixar Rodando Continuamente
```
MAX_ATTEMPTS = 0 (infinito)
WAIT_BETWEEN_ATTEMPTS = 60
```
Deixe o job rodando até conseguir (pode levar horas ou dias).

### Estratégia 2: Tentar em Horários Específicos
Configure um **Cron Job no Jenkins**:
```
# Tentar todo dia às 3h da manhã (horário de Brasília)
H 3 * * *
```

### Estratégia 3: Múltiplas Tentativas Rápidas
```
MAX_ATTEMPTS = 100
WAIT_BETWEEN_ATTEMPTS = 30
```
Tenta 100 vezes com 30s de intervalo (~50 minutos total).

### Estratégia 4: Notificações
Adicione ao Jenkinsfile:
```groovy
post {
    success {
        // Email
        emailext (
            subject: "✅ VM Oracle ARM Criada!",
            body: "IP: ${PUBLIC_IP}",
            to: "seu@email.com"
        )
        
        // Slack
        slackSend (
            color: 'good',
            message: "✅ VM ARM criada! IP: ${PUBLIC_IP}"
        )
    }
}
```

---

## 🐛 Troubleshooting

### Erro: "Authentication failed"
```bash
# Verifique as credentials
# Confirme que o fingerprint está correto
# Teste manualmente:
oci iam user get --user-id <seu_user_ocid>
```

### Erro: "Out of capacity" persistente
**Soluções:**
1. Continue tentando (pode levar dias)
2. Tente horários alternativos (madrugada)
3. Reduza recursos temporariamente (2 OCPU em vez de 4)

### Erro: "Service limits exceeded"
```bash
# Verifique se já tem instâncias ARM criadas
# Você só pode ter 4 OCPUs total no Always Free
# Delete instâncias antigas se necessário
```

### Jenkins fica travado
```bash
# Adicione timeout no Jenkinsfile:
timeout(time: 24, unit: 'HOURS') {
    // ... seu código
}
```

### Terraform state lock
```bash
# Se o job for interrompido, pode travar o state
# Limpe manualmente:
cd /var/lib/jenkins/workspace/Oracle-ARM-Retry/
rm -f .terraform.tfstate.lock.info
```

---

## 📊 Monitoramento

### Ver Progresso em Tempo Real

**Opção 1: Console do Jenkins**
```
Job → Build #X → Console Output
```

**Opção 2: Tail do log**
```bash
tail -f /var/lib/jenkins/jobs/Oracle-ARM-Retry/builds/<BUILD_NUMBER>/log
```

### Estatísticas

O script mostra automaticamente:
- ✅ Número de tentativas
- ⏱️ Tempo total decorrido
- 🎯 Taxa de sucesso

---

## 🎉 Após Conseguir a VM

### Primeiras configurações

```bash
# Conectar
ssh -i ~/.ssh/oracle_vm_key ubuntu@<IP>

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

### Abrir portas no Oracle Cloud

No console Oracle:
```
Networking → Virtual Cloud Networks → Sua VCN → 
Security Lists → Default Security List → Add Ingress Rule
```

---

## 💡 Dicas Extras

1. **Backup da configuração**: Versione seus arquivos .tf no Git

2. **Múltiplas VMs**: Ajuste o `count` no main.tf para criar 4 VMs menores

3. **Diferentes regiões**: Crie jobs separados para diferentes regiões

4. **Auto-destroy**: Adicione stage para destruir VMs antigas se necessário

5. **Logs detalhados**: Configure `TF_LOG=DEBUG` para debug avançado

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs do Jenkins
2. Teste o OpenTofu/Terraform manualmente
3. Confirme as credentials na Oracle Cloud
4. Verifique limites de serviço na Oracle

---

## ✅ Checklist Rápido

- [ ] OpenTofu/Terraform instalado
- [ ] Jenkins configurado e rodando
- [ ] API Key criada na Oracle
- [ ] Todos os OCIDs coletados
- [ ] Chaves SSH criadas
- [ ] Credentials adicionadas no Jenkins
- [ ] Job pipeline criado
- [ ] main.tf no workspace
- [ ] Primeira execução testada

---

**Boa sorte! 🍀 Com persistência você consegue a VM ARM!**

*Última atualização: Novembro 2025*
