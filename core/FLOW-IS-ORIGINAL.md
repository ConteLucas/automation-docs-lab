# O que é `is_original`?

**is_original** é um campo booleano na tabela **flow** (a collection).

- **`is_original = true`**  
  Significa: *esta collection é a referência oficial* — a que está mais atualizada e em uso (produção, “a que funciona”). Você usa essa marca para saber qual fluxo não deve ser alterado à toa quando estiver editando cópias de teste.

- **`is_original = false`**  
  Significa: *esta collection é uma cópia / ambiente de teste* — pode ser editada à vontade (criar steps, mudar imagens, testar) sem interferir no fluxo que está rodando de verdade.

Assim você pode ter, por exemplo:
- Collection "LOGIN produção" → `is_original = true` (não mexe).
- Collection "LOGIN teste" → `is_original = false` (edita à vontade).

Quem determina qual é a “original” é você, ao criar ou editar a collection (checkbox ou toggle no formulário).
