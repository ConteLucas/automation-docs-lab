# Revisão da modelagem: Core (REQUEST, REQUEST_DETAIL, etc.)

Documento de revisão crítica: o que faz sentido, o que está consistente e onde estão os gaps. Complementa o [CORE-REQUESTS-STRATEGY.md](CORE-REQUESTS-STRATEGY.md).

---

## O que faz sentido e está consistente

- **REQUEST → REQUEST_DETAIL (1:N):** Um pedido com várias linhas (detalhes) reflete bem "um pedido com range/ALL/servidor único". Status do REQUEST derivado dos detalhes (todas FINISHED → REQUEST FINISHED; uma ERROR → REQUEST ERROR) é coerente.

- **SERVER único no REQUEST:** Um campo só (ALL | range_1…6 | S1…S65) evita duplicação e ambiguidade. REQUEST_DETAIL.server_value indica "qual posição/servidor desta linha" e faz sentido para o bot processar em ordem (line_index).

- **CONFIG para ALL:** SERVER_ALL=65 (ou N) na CONFIG permite mudar a quantidade de linhas de ALL sem alterar código. Consistente com "ALL só no REQUEST e gera N detalhes".

- **Batch 6h em REQUEST_DETAIL.updated_at:** Critério objetivo para "device parou de reportar". Devolver só o detalhe (e o REQUEST quando todos os detalhes voltarem a PENDING) permite que outro device pegue o mesmo pedido. Faz sentido.

- **DEBUG_IMAGE + REQUEST_LOG.debug_image_id:** Screenshot da Vision fica ligado ao pedido/detalhe e ao momento do erro (log com last_click + message + debug_image_id). Atende ao objetivo de "explicar onde clicou e o que a Vision viu".

- **priority + id na ordem de entrega:** Prioridade primeiro, depois ordem de criação (id). Alinha com "mirar" em pedidos mais urgentes.

- **active_flag + device_id no REQUEST:** "Quem pegou" e "está em uso" ficam explícitos; ao devolver (batch), zeramos e o pedido volta para a fila. Consistente.

---

## Gaps e refinamentos

### 1. Quantidade de linhas por range (range_1 … range_6)

Hoje só CONFIG.SERVER_ALL está definido. Para **range_1** (1–9), **range_2** (10–17), etc., o Core precisa saber **quantas** REQUEST_DETAIL criar.

- **Opção A:** CONFIG com chaves `RANGE_1_COUNT=9`, `RANGE_2_COUNT=8`, … (e range_6 "resto" definido por exclusão ou outra chave).
- **Opção B:** Tabela **RANGE_CONFIG** (server, from_pos, to_pos) ou (server, count).

**Gap:** sem isso, a geração de REQUEST_DETAIL para ranges fica hardcoded ou incompleta.

---

### 2. Concorrência no GET /requests/next

Dois devices chamando ao mesmo tempo podem receber o mesmo REQUEST se não houver proteção.

- **Refinamento:** transação com `SELECT ... FOR UPDATE` (ou equivalente), ou "reserva" atômica: ao escolher o REQUEST, já atualizar active_flag=1 e device_id na **mesma transação** antes de devolver a resposta. Assim só um device "leva" aquele pedido.

---

### 3. Timeout 6h fixo

Hoje 6h está implícito. Se no futuro quiser 4h ou 12h, exige mudança de código.

- **Refinamento:** CONFIG com chave `REQUEST_DETAIL_TIMEOUT_HOURS=6` (ou em minutos). Batch lê da CONFIG.

---

### 4. Semântica de REQUEST_DETAIL.server_value

Para ALL: "1"…"65" (ou "S1"…"S65"). Para range_1: "1"…"9". Para servidor único: "S3". O **valor** é string e o **significado** depende do REQUEST.server (ALL vs range_X vs S?).

- **Refinamento:** documentar no modelo (ou no CONFIG) a convenção: ex. "para ALL e ranges, server_value é numérico 1..N; para servidor único, prefixo S". Assim o bot e o Core interpretam igual.

---

### 5. Tabela DEVICE (opcional)

Autenticação hoje: device_id + header (token/API key). Para validar o header, o Core precisa saber se aquele token pertence àquele device_id.

- **Gap opcional:** tabela **DEVICE** (id, name, api_key_hash ou token, active, created_at) para cadastro e validação. Se "device_id + header" for só um segredo compartilhado por device, dá para viver sem tabela; se quiser listar devices, revogar, etc., a tabela ajuda.

---

### 6. REQUEST_DETAIL.device_id

Quando um device pega o REQUEST inteiro, todos os detalhes são dele. O device_id no REQUEST já indica isso. REQUEST_DETAIL.device_id fica útil no **batch:** ao devolver um detalhe para PENDING, limpamos device_id naquele detalhe; e para auditoria ("quem estava processando esta linha quando deu timeout"). Pode manter; não é redundância inútil.

---

### 7. Range 6 ("o resto")

Ainda não está definido qual conjunto numérico é "range_6".

- **Gap:** definir em CONFIG ou RANGE_CONFIG (ex.: intervalos ou lista de números) para a geração de REQUEST_DETAIL e para o bot saber o que processar.

---

### 8. Fluxo de REQUEST_DETAIL: quando vira PROCESSING

O device pega o REQUEST (todos os detalhes vêm PENDING). Ao **começar** a processar a linha N, faz sentido o device dar PUT naquele REQUEST_DETAIL com status=PROCESSING (e o Core atualiza updated_at). Assim o batch 6h faz sentido por detalhe (última atividade naquela linha). Está implícito; vale deixar explícito no doc que o device pode fazer PUT com PROCESSING ao iniciar uma linha.

---

### 9. Dados sensíveis (login, password)

REQUEST guarda login/senha. Não é gap de modelagem, mas de segurança: considerar criptografia em repouso ou uso de vault; importante para implementação.

---

## Conclusão

- A modelagem **faz sentido** para o fluxo descrito (pedido → detalhes → device pega um → reporta por linha → timeout devolve → log + screenshot no erro).

- Os **gaps principais** são:
  1. **Como gerar N linhas para cada range** → CONFIG ou RANGE_CONFIG.
  2. **Concorrência no GET next** → transação/lock.
  3. **Timeout configurável** → CONFIG.
  4. **Convenção de server_value** → documentação.
  5. **Range 6 explícito** → definir conjunto.

- **DEVICE** e **criptografia de credenciais** são refinamentos opcionais.

- **Recomendação:** fechar CONFIG/RANGE_CONFIG e regra de geração de REQUEST_DETAIL por range **antes** de implementar; concorrência e timeout já na Fase 1 do Core.
