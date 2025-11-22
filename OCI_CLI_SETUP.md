# 🔧 Configuração do OCI CLI

## ✅ Instalação Concluída

- ✅ **OCI CLI v3.70.1** instalado com sucesso
- ✅ Localização: `/usr/bin/oci`

## 📋 Próximos Passos - Configurar o OCI CLI

### 1️⃣ Configuração Interativa (Recomendado)

Execute o comando de configuração:

```bash
oci setup config
```

O assistente vai perguntar:

1. **Localização do arquivo de configuração**: 
   - Pressione Enter para aceitar o padrão: `~/.oci/config`

2. **User OCID**: 
   - Cole o OCID do seu usuário (ex: `ocid1.user.oc1..aaaaa...`)
   - Encontre em: Oracle Cloud Console → User Settings

3. **Tenancy OCID**: 
   - Cole o OCID do tenancy (ex: `ocid1.tenancy.oc1..aaaaa...`)
   - Encontre em: Oracle Cloud Console → Tenancy Details

4. **Region**: 
   - Digite a região (ex: `us-ashburn-1`)

5. **Gerar nova chave API?**
   - Digite `Y` se ainda não tem chave
   - Digite `n` se já criou a chave manualmente

6. **Localização da chave privada**:
   - Se gerou nova: aceite o padrão `~/.oci/oci_api_key.pem`
   - Se já tem: digite o caminho da sua chave

### 2️⃣ Adicionar a Chave Pública na Oracle Cloud

Se o CLI gerou uma nova chave, você precisa adicionar a chave pública:

```bash
# Mostrar a chave pública
cat ~/.oci/oci_api_key_public.pem
```

**Depois:**
1. Acesse https://cloud.oracle.com
2. Vá em: Ícone do usuário → User Settings → API Keys → Add API Key
3. Cole o conteúdo da chave pública
4. Clique em "Add"

### 3️⃣ Testar a Configuração

```bash
# Listar regiões disponíveis
oci iam region list

# Listar compartments
oci iam compartment list

# Ver informações do usuário
oci iam user get --user-id <seu-user-ocid>
```

## 📝 Estrutura do Arquivo de Configuração

O arquivo `~/.oci/config` terá este formato:

```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaa...
fingerprint=aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99
tenancy=ocid1.tenancy.oc1..aaaaaaaa...
region=us-ashburn-1
key_file=~/.oci/oci_api_key.pem
```

## 🔑 Comandos Úteis do OCI CLI

### Listar Instâncias
```bash
# Listar todas as instâncias em um compartment
oci compute instance list --compartment-id <compartment-ocid>

# Listar com formato de tabela
oci compute instance list --compartment-id <compartment-ocid> --output table
```

### Listar Imagens ARM
```bash
# Listar imagens Ubuntu ARM
oci compute image list \
  --compartment-id <compartment-ocid> \
  --operating-system "Canonical Ubuntu" \
  --shape "VM.Standard.A1.Flex" \
  --output table
```

### Listar VCNs
```bash
# Listar Virtual Cloud Networks
oci network vcn list --compartment-id <compartment-ocid>
```

### Listar Availability Domains
```bash
# Listar domínios de disponibilidade
oci iam availability-domain list --compartment-id <compartment-ocid>
```

### Criar Instância (exemplo)
```bash
# Criar uma instância ARM (exemplo básico)
oci compute instance launch \
  --availability-domain <AD-name> \
  --compartment-id <compartment-ocid> \
  --shape VM.Standard.A1.Flex \
  --shape-config '{"ocpus":4,"memoryInGBs":24}' \
  --image-id <image-ocid> \
  --subnet-id <subnet-ocid> \
  --display-name "my-arm-instance"
```

## 🔍 Troubleshooting

### Erro: "Authentication failed"
```bash
# Verificar configuração
cat ~/.oci/config

# Verificar permissões da chave
ls -l ~/.oci/oci_api_key.pem
# Deve ser: -rw------- (600)

# Corrigir permissões se necessário
chmod 600 ~/.oci/oci_api_key.pem
```

### Erro: "Service error: NotAuthenticated"
- Verifique se a chave pública foi adicionada na Oracle Cloud
- Confirme que o fingerprint está correto
- Verifique se o User OCID está correto

### Erro: "Invalid key file"
```bash
# Verificar se a chave é válida
openssl rsa -in ~/.oci/oci_api_key.pem -check
```

## 📚 Documentação

- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
- [OCI CLI Command Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref.html)
- [OCI CLI GitHub](https://github.com/oracle/oci-cli)

## 💡 Dicas

1. **Múltiplos Perfis**: Você pode ter múltiplos perfis no `~/.oci/config`:
   ```ini
   [DEFAULT]
   user=ocid1.user...
   
   [PROFILE2]
   user=ocid1.user...
   ```
   
   Use com: `oci --profile PROFILE2 ...`

2. **Auto-complete**: Habilite auto-complete no shell:
   ```bash
   # Para bash
   echo 'eval "$(oci setup autocomplete)"' >> ~/.bashrc
   
   # Para zsh
   echo 'eval "$(oci setup autocomplete)"' >> ~/.zshrc
   ```

3. **Debug**: Use `--debug` para ver detalhes:
   ```bash
   oci compute instance list --compartment-id <id> --debug
   ```

4. **Formato de Saída**: Escolha o formato:
   ```bash
   # JSON (padrão)
   oci ... --output json
   
   # Tabela
   oci ... --output table
   
   # YAML
   oci ... --output yaml
   ```

## ✅ Checklist

- [ ] OCI CLI instalado (`oci --version`)
- [ ] Configuração criada (`oci setup config`)
- [ ] Chave pública adicionada na Oracle Cloud
- [ ] Teste de conexão bem-sucedido (`oci iam region list`)
- [ ] Compartment OCID identificado

---

**Pronto! Agora você pode usar o OCI CLI para gerenciar seus recursos na Oracle Cloud! 🚀**
