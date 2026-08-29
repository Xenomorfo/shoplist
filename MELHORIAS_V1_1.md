# ShopList 1.1 — revisão da aplicação

## Correções funcionais

- Corrigido o fluxo de conclusão de compras: cada lista é arquivada separadamente e numa transação SQLite atómica.
- Corrigida a associação entre `listItems`, itens do catálogo e itens do histórico.
- O histórico passa a guardar corretamente o estado comprado/pendente (`wasBought`).
- Reutilizar produtos do histórico deixa de reutilizar IDs de tabelas incompatíveis; o produto é resolvido pelo catálogo ou recriado de forma segura.
- IDs reais da base de dados são usados nas operações de editar/apagar em vez da posição visual na lista.
- Quantidades SQLite inteiras ou reais são convertidas de forma segura para `double`.
- Evitados produtos duplicados dentro da mesma lista de compras.
- Eliminação de listas/itens limpa referências dependentes; categorias e unidades em uso ficam protegidas.
- Dashboard deixa de depender de atualizações periódicas e passa a carregar imediatamente e a atualizar após navegação/pull-to-refresh.
- Splash screen restaura o modo normal da interface do sistema depois de abrir a aplicação.
- Corrigidas categorias, unidades e associações incoerentes nos dados predefinidos, incluindo migração de instalações existentes e limpeza segura de referências órfãs antigas.

## Interface e experiência

- Novo sistema visual Material 3 consistente em toda a aplicação.
- Dashboard responsivo com hero, KPIs, ações rápidas, listas recentes, modelos, categorias mais usadas e atividade.
- Cartões, margens, tipografia, estados vazios, pesquisas e confirmações uniformizados.
- Pesquisa e filtros no catálogo, listas, categorias e unidades.
- Fluxo de compras com progresso global e por lista.
- Selecionar/desmarcar todos os itens e remover um item diretamente da compra.
- Edição de itens com validação, notas, categoria e unidade corretamente carregadas.
- Gestão de unidades inclui agora o campo Tipo que existia no modelo mas não era editável.
- Categorias podem ser ativadas/desativadas corretamente.
- Tema claro/escuro/sistema persistente.
- Metadados web/mobile e branding atualizados para ShopList.

## Funcionalidades acrescentadas

- Reutilização seletiva de itens de compras antigas.
- Prevenção de duplicados na seleção de compras.
- Atividade recente com opção para limpar apenas o registo de atividade.
- Indicadores de progresso e estatísticas do catálogo/listas/histórico.
- Pesquisa contextual e seleção por categorias.
