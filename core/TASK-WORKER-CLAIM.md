# Worker: reivindicar tarefa

O **device não é escolhido** ao gerar tarefas no painel. Cada tarefa nasce em **PENDING** com `device_id` nulo.

O app no dispositivo chama o core com o **mesmo `identifier`** cadastrado em `/api/devices`:

```http
POST /api/tasks/claim-next
Content-Type: application/json

{
  "deviceIdentifier": "nome-ou-id-do-device",
  "deviceApiKey": "secret-do-device"
}
```

**Produção:** `deviceApiKey` obrigatória (hash BCrypt em `device.api_key_hash`). Bearer de usuário CRM **não** substitui a API key.

**Dev/docker:** com `APP_SECURITY_WORKER_REQUIRE_DEVICE_KEY=false`, a api key é opcional.

- **200**: plano worker — tarefa passou a **PROCESSING** e `device_id` passa a ser o device que reivindicou.
- **204**: não há tarefa **PENDING** nem **ERROR** na fila.
- **401**: api key ausente/inválida (prod).
- **404**: `deviceIdentifier` não existe.
- **409**: device **INATIVO/DEPRECADO** ou removido (soft delete).

Ordem das tarefas: menor `id` primeiro (FIFO simples).

## Planos worker (GET)

Em produção, inclua headers:

```http
X-Device-Identifier: device-android-001
X-Device-Api-Key: secret-do-device
```

Dev seeds: `device-android-001` / `dev-device-key-001` (via `./bootstrap.sh`).
