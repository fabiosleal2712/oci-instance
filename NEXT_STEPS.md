# 🎯 Próximos Passos - Configuração Rápida

## ✅ Status do Projeto

- ✅ Projeto criado com sucesso
- ✅ OpenTofu v1.10.7 instalado e funcionando
- ✅ Configuração validada
- ✅ Provider Oracle OCI v5.47.0 instalado

## 📋 O que você precisa fazer agora:

### 1️⃣ Configurar API Keys na Oracle Cloud

```bash
# Criar diretório para as chaves
mkdir -p ~/.oci

# Gerar par de chaves
cd ~/.oci
openssl genrsa -out oci_api_key.pem 2048
openssl rsa -pubout -in oci_api_key.pem -out oci_api_key_public.pem
chmod 600 oci_api_key.pem
chmod 644 oci_api_key_public.pem

# Mostrar chave pública para copiar
cat oci_api_key_public.pem
```

**Depois:**
1. Acesse https://cloud.oracle.com
2. Vá em: Ícone do usuário → User Settings → API Keys → Add API Key
3. Cole o conteúdo de `oci_api_key_public.pem`
4. **IMPORTANTE**: Copie o "Configuration File Preview" que aparece

### 2️⃣ Criar chave SSH para as VMs

```bash
# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oracle_vm_key -N ""

# Mostrar chave pública
cat ~/.ssh/oracle_vm_key.pub
```

### 3️⃣ Coletar OCIDs necessários

Você precisa dos seguintes valores (aparecem no "Configuration File Preview"):

- ✅ `tenancy_ocid` - OCID do Tenancy
- ✅ `user_ocid` - OCID do User
- ✅ `fingerprint` - Fingerprint da API Key
- ✅ `region` - Região (ex: us-ashburn-1)
- ✅ `compartment_ocid` - OCID do Compartment (Identity & Security → Compartments)

### 4️⃣ Configurar Credentials no Jenkins

Acesse: `Jenkins → Manage Jenkins → Credentials → System → Global credentials`

**Adicione as seguintes credentials (tipo "Secret text"):**

| ID da Credential | Valor | Onde encontrar |
|------------------|-------|----------------|
| `oracle-tenancy-ocid` | `ocid1.tenancy.oc1..aaaaa...` | Configuration File Preview |
| `oracle-user-ocid` | `ocid1.user.oc1..aaaaa...` | Configuration File Preview |
| `oracle-fingerprint` | `aa:bb:cc:dd:...` | Configuration File Preview |
| `oracle-compartment-ocid` | `ocid1.compartment.oc1..aaaaa...` | Identity & Security → Compartments |
| `oracle-ssh-public-key` | `ssh-rsa AAAAB3N...` | Conteúdo de `~/.ssh/oracle_vm_key.pub` |

**Adicione uma credential (tipo "Secret file"):**

| ID da Credential | Arquivo | Onde encontrar |
|------------------|---------|----------------|
| `oracle-private-key-file` | Upload do arquivo | `~/.oci/oci_api_key.pem` |

### 5️⃣ Criar Pipeline Job no Jenkins

1. **Criar novo Job**
   - Jenkins → New Item
   - Nome: `Oracle-ARM-Retry`
   - Tipo: Pipeline
   - Clique em "OK"

2. **Configurar o Job**
   - Marque: "This project is parameterized"
   - Em "Pipeline Definition": escolha "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `file:///home/fabioleal/github/oci-instance` (ou URL do seu Git)
   - Script Path: `Jenkinsfile`
   - Salve

   **OU** (alternativa mais simples):
   - Em "Pipeline Definition": escolha "Pipeline script"
   - Cole o conteúdo do arquivo `Jenkinsfile`
   - Salve

### 6️⃣ Executar o Pipeline

1. Vá em: `Jenkins → Oracle-ARM-Retry → Build with Parameters`

2. Configure os parâmetros:
   ```
   MAX_ATTEMPTS: 1000 (ou 0 para infinito)
   WAIT_BETWEEN_ATTEMPTS: 60
   OCPU_COUNT: 4
   MEMORY_GB: 24
   BOOT_VOLUME_GB: 200
   REGION: us-ashburn-1
   ```

3. Clique em "Build"

4. Monitore em: `Console Output`

## 🧪 Testar localmente (opcional)

Se quiser testar antes de usar o Jenkins:

```bash
# 1. Criar arquivo terraform.tfvars com suas credenciais
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edite com seus valores reais

# 2. Testar o plano
tofu plan

# 3. Aplicar (criar recursos)
tofu apply

# 4. Destruir (remover recursos)
tofu destroy
```

## 📚 Documentação

- **Guia completo**: [`setup_instructions.md`](setup_instructions.md)
- **README**: [`README.md`](README.md)

## ⚠️ Importante

- **NÃO commite** arquivos com credenciais (`.tfvars`, `.pem`, etc.)
- O `.gitignore` já está configurado para proteger arquivos sensíveis
- Mantenha suas chaves privadas seguras

## 🎉 Quando conseguir criar a VM

O Jenkins mostrará:
```
✅ SUCESSO! Instância criada com sucesso!
📡 IP Público: 140.238.123.456
🔑 Comando SSH: ssh ubuntu@140.238.123.456
```

Conecte usando:
```bash
ssh -i ~/.ssh/oracle_vm_key ubuntu@<IP_PUBLICO>
```

---

**Boa sorte! 🍀**
