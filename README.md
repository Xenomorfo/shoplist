# ShopList

Aplicação Flutter para gerir listas de compras, catálogo de produtos, categorias, unidades e histórico, com armazenamento local em SQLite.

## Principais funcionalidades

- Dashboard com indicadores, atividade recente e ações rápidas.
- Listas pessoais e modelos predefinidos.
- Catálogo pesquisável com categorias, quantidades, unidades e notas.
- Seleção de produtos por categoria e prevenção de duplicados na mesma lista.
- Acompanhamento da compra com progresso por lista, marcar/desmarcar todos e conclusão individual.
- Histórico detalhado que preserva o estado comprado/pendente e permite reutilizar itens numa nova compra.
- Gestão de categorias e unidades com proteção contra eliminações que quebrariam referências.
- Tema claro, escuro ou automático, persistido no dispositivo.
- Interface Material 3 responsiva para telemóvel, tablet e desktop.

## Executar

```bash
flutter pub get
flutter run
```

## Validação recomendada

```bash
flutter analyze
flutter test
```

Para voltar a gerar ícones e ecrãs de arranque depois de alterar `images/shoplist_icon.png`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Dados

A aplicação continua a usar SQLite local. A base de dados foi atualizada para a versão 2 e inclui uma migração conservadora dos dados predefinidos antigos, sem apagar as listas e compras do utilizador.
