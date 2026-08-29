import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// Note: Já não precisamos de importar 'category.dart' aqui.

class DatabaseHelper {
  // 1. Singleton (Padrão de Criação)
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;

  DatabaseHelper._instance();

  // 2. Getter Assíncrono para a Base de Dados
  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  // 3. Inicialização da Base de Dados
  Future<Database> initDb() async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'shoplist.db');

    _database = await openDatabase(
      path,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (database) async {
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_listitems_list ON listItems(listId)',
        );
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_listitems_item ON listItems(itemId)',
        );
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_items_category ON items(categoryId)',
        );
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_historyitems_list ON historyItems(listHistoryId)',
        );
      },
    );

    return _database!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Corrige apenas dados predefinidos antigos, sem alterar conteúdo criado pelo utilizador.
      await db.update(
        'lists',
        {'name': 'Refeições e Despensa'},
        where: "isPredefined = 1 AND name = ?",
        whereArgs: ['Sobremesas'],
      );
      await db.update(
        'items',
        {'listId': 4},
        where: 'listId = 3 AND name IN (?, ?)',
        whereArgs: ['Bacalhau', 'Salmão'],
      );
      await db.update(
        'items',
        {'unityId': 2},
        where: 'name = ? AND unityId = 1',
        whereArgs: ['Leite'],
      );
      await db.update(
        'items',
        {'categoryId': 7},
        where: 'name = ? AND categoryId = 5',
        whereArgs: ['Vinagre'],
      );
      await db.update(
        'items',
        {'categoryId': 13},
        where: 'name = ? AND categoryId = 15',
        whereArgs: ['Gelado'],
      );
      await db.update(
        'items',
        {'unityId': 5},
        where: 'name IN (?, ?, ?) AND unityId = 1',
        whereArgs: ['Papel Higienico', 'Rolo Cozinha', 'Champô'],
      );
      await db.update(
        'categories',
        {'name': 'Laticínios'},
        where: 'name = ?',
        whereArgs: ['Laticinios'],
      );
      await db.update(
        'categories',
        {'name': 'Utensílios'},
        where: 'name = ?',
        whereArgs: ['Utensilios'],
      );


      // Repara referências órfãs que versões antigas podiam permitir com
      // foreign_keys desativado. Mantém o máximo de dados possível.
      await db.execute('''
        UPDATE items
        SET categoryId = NULL
        WHERE categoryId IS NOT NULL
          AND categoryId NOT IN (SELECT id FROM categories)
      ''');
      await db.execute('''
        UPDATE items
        SET unityId = NULL
        WHERE unityId IS NOT NULL
          AND unityId NOT IN (SELECT id FROM unities)
      ''');
      await db.execute('''
        UPDATE items
        SET listId = NULL
        WHERE listId IS NOT NULL
          AND listId NOT IN (SELECT id FROM lists)
      ''');
      await db.execute('''
        UPDATE historyItems
        SET categoryId = NULL
        WHERE categoryId IS NOT NULL
          AND categoryId NOT IN (SELECT id FROM categories)
      ''');
      await db.execute('''
        UPDATE historyItems
        SET unityId = NULL
        WHERE unityId IS NOT NULL
          AND unityId NOT IN (SELECT id FROM unities)
      ''');
      await db.execute('''
        DELETE FROM historyItems
        WHERE listHistoryId IS NULL
           OR listHistoryId NOT IN (SELECT id FROM historyLists)
      ''');
      await db.execute('''
        DELETE FROM listItems
        WHERE listId IS NULL
           OR itemId IS NULL
           OR listId NOT IN (SELECT id FROM lists)
           OR itemId NOT IN (SELECT id FROM items)
      ''');
    }
  }

  // 4. Criação do Schema (CRÍTICO)
  Future<void> _onCreate(Database db, int version) async {
    // 💥 Tabela Categorias
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT,
        icon TEXT,
        color TEXT,
        isActive BOOLEAN
      )
    ''');
    // 💥 Tabela Unidades
    await db.execute('''
      CREATE TABLE unities (
        id INTEGER PRIMARY KEY,
        name TEXT,
        acronym TEXT,
        type TEXT
      )
    ''');
    // 💥 Tabela Listas
    await db.execute('''
      CREATE TABLE lists (
        id INTEGER PRIMARY KEY,
        name TEXT,
        createdAt DATE,
        updatedAt DATE,
        isPredefined BOOLEAN
      )
    ''');

    // 💥 Tabela Itens
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        listId INTEGER,
        name TEXT,
        qty REAL,
        unityId INTEGER,
        categoryId INTEGER,
        isBought BOOLEAN DEFAULT 0,
        notes TEXT,
        createdAt DATETIME,
        updatedAt DATETIME,
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (unityId) REFERENCES unities(id),
        FOREIGN KEY (listId) REFERENCES lists(id)
        
      )
    ''');

    // 💥 Tabela Histórico de Listas
    await db.execute('''
      CREATE TABLE historyLists (
        id INTEGER PRIMARY KEY,
        name TEXT,
        createdAt DATE,
        endedAt DATE,
        totalItems INTEGER,
        totalBought INTEGER
        
      )
    ''');

    // 💥 Tabela Itens Historicos
    await db.execute('''
      CREATE TABLE historyItems (
        id INTEGER PRIMARY KEY,
        listHistoryId INTEGER,
        name TEXT,
        qty REAL,
        unityId INTEGER,
        categoryId INTEGER,
        wasBought BOOLEAN,
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (unityId) REFERENCES unities(id),
        FOREIGN KEY (listHistoryId) REFERENCES historyLists(id)
        
      )
    ''');

    // 💥 Tabela lista_itens
    await db.execute('''
      CREATE TABLE listItems (
        id INTEGER PRIMARY KEY,
        listId INTEGER,
        itemId INTEGER,
        qty REAL,
        notes TEXT,
        isChecked BOOLEAN,
        FOREIGN KEY (listId) REFERENCES lists(id),
        FOREIGN KEY (itemId) REFERENCES items(id)
        
      )
    ''');

    await _initializeDefaultData(db);
  }

  Future<void> _initializeDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Charcutaria', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Bebidas', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Carne', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Laticínios', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Detergentes', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Utensílios', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Mercearia', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Fruta', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Legumes', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Peixe', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Higiene', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Enlatados', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Congelados', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Padaria', 'icon': '', 'color': '', 'isActive': 1},
      {'name': 'Outros', 'icon': '', 'color': '', 'isActive': 1},
    ];

    List<Map<String, dynamic>> defaultUnities = [
      {'name': 'Kilo', 'acronym': 'Kg', 'type': 'Unidade'},
      {'name': 'Litro', 'acronym': 'L', 'type': 'Unidade'},
      {'name': 'Gramas', 'acronym': 'gr', 'type': 'SubUnidade'},
      {'name': 'Centimetros', 'acronym': 'cm', 'type': 'SubUnidade'},
      {'name': 'Unidade', 'acronym': 'uni', 'type': 'Unidade'},
    ];

    List<Map<String, dynamic>> lists = [
      {
        'name': 'Lista da Semana',
        'createdAt': now,
        'updatedAt': now,
        'isPredefined': 1,
      },
      {
        'name': 'Pequenas Compras',
        'createdAt': now,
        'updatedAt': now,
        'isPredefined': 1,
      },
      {
        'name': 'Limpeza da Casa',
        'createdAt': now,
        'updatedAt': now,
        'isPredefined': 1,
      },
      {
        'name': 'Refeições e Despensa',
        'createdAt': now,
        'updatedAt': now,
        'isPredefined': 1,
      },
    ];

    List<Map<String, dynamic>> items = [
      {
        'listId': 4,
        'name': 'Carne Picada',
        'qty': 500,
        'unityId': 3,
        'categoryId': 3,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Bacalhau',
        'qty': 500,
        'unityId': 3,
        'categoryId': 10,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Salmão',
        'qty': 500,
        'unityId': 3,
        'categoryId': 10,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Bifanas',
        'qty': 300,
        'unityId': 3,
        'categoryId': 3,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Costoletas',
        'qty': 500,
        'unityId': 3,
        'categoryId': 3,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Leite',
        'qty': 1,
        'unityId': 2,
        'categoryId': 4,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Iogurtes',
        'qty': 6,
        'unityId': 5,
        'categoryId': 4,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Cogumelos',
        'qty': 3,
        'unityId': 5,
        'categoryId': 12,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Salsichas',
        'qty': 1,
        'unityId': 5,
        'categoryId': 12,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Atum',
        'qty': 3,
        'unityId': 5,
        'categoryId': 12,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Vinagre',
        'qty': 2,
        'unityId': 5,
        'categoryId': 7,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 4,
        'name': 'Batatas Congeladas',
        'qty': 1,
        'unityId': 1,
        'categoryId': 13,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 3,
        'name': 'Limpa Móveis',
        'qty': 2,
        'unityId': 5,
        'categoryId': 5,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 3,
        'name': 'Esfregona',
        'qty': 1,
        'unityId': 5,
        'categoryId': 6,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 3,
        'name': 'Panos',
        'qty': 5,
        'unityId': 5,
        'categoryId': 6,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 3,
        'name': 'Alcool',
        'qty': 2,
        'unityId': 5,
        'categoryId': 5,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 3,
        'name': 'Sanita',
        'qty': 1,
        'unityId': 5,
        'categoryId': 5,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Agua',
        'qty': 1,
        'unityId': 5,
        'categoryId': 2,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Gelado',
        'qty': 500,
        'unityId': 3,
        'categoryId': 13,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Pão',
        'qty': 4,
        'unityId': 5,
        'categoryId': 14,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Arroz',
        'qty': 1,
        'unityId': 1,
        'categoryId': 7,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Massa',
        'qty': 1,
        'unityId': 1,
        'categoryId': 7,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Alho',
        'qty': 1,
        'unityId': 1,
        'categoryId': 9,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Cebola',
        'qty': 1,
        'unityId': 1,
        'categoryId': 9,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },

      {
        'listId': 4,
        'name': 'Bolachas',
        'qty': 1,
        'unityId': 5,
        'categoryId': 15,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Cerveja',
        'qty': 1,
        'unityId': 2,
        'categoryId': 2,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Vinho',
        'qty': 1,
        'unityId': 2,
        'categoryId': 2,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Sumol',
        'qty': 1,
        'unityId': 2,
        'categoryId': 2,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Maçãs',
        'qty': 1,
        'unityId': 1,
        'categoryId': 8,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Bananas',
        'qty': 300,
        'unityId': 3,
        'categoryId': 8,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Peras',
        'qty': 300,
        'unityId': 3,
        'categoryId': 8,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Uvas',
        'qty': 500,
        'unityId': 3,
        'categoryId': 8,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Ovos',
        'qty': 6,
        'unityId': 5,
        'categoryId': 7,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Queijo',
        'qty': 200,
        'unityId': 3,
        'categoryId': 1,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 1,
        'name': 'Fiambre',
        'qty': 200,
        'unityId': 3,
        'categoryId': 1,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Papel Higienico',
        'qty': 6,
        'unityId': 5,
        'categoryId': 11,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Rolo Cozinha',
        'qty': 6,
        'unityId': 5,
        'categoryId': 11,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'listId': 2,
        'name': 'Champô',
        'qty': 2,
        'unityId': 5,
        'categoryId': 11,
        'isBought': 0,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (var categoryMap in defaultCategories) {
      await db.insert('categories', categoryMap);
    }
    for (var unityMap in defaultUnities) {
      await db.insert('unities', unityMap);
    }
    for (var listMap in lists) {
      await db.insert('lists', listMap);
    }
    for (var itemMap in items) {
      await db.insert('items', itemMap);
    }
  }
}
