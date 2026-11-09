import 'dart:io';
import 'package:flutter/material.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const ReadRankApp());
}

class ReadRankApp extends StatelessWidget {
  const ReadRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadRank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final BookStatus status;
  int? rank;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    this.rank,
  });
}

enum BookStatus { read, wishlist }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WidgetsToImageController _imageController = WidgetsToImageController();

  final List<Book> _books = [
    Book(id: '1', title: 'Dom Casmurro', author: 'Machado de Assis', status: BookStatus.read, rank: 1),
    Book(id: '2', title: 'O Senhor dos Anéis', author: 'J.R.R. Tolkien', status: BookStatus.read, rank: 2),
    Book(id: '3', title: '1984', author: 'George Orwell', status: BookStatus.read, rank: 3),
    Book(id: '4', title: 'Duna', author: 'Frank Herbert', status: BookStatus.read, rank: 4),
    Book(id: '5', title: 'O Hobbit', author: 'J.R.R. Tolkien', status: BookStatus.read, rank: 5),
    Book(id: '6', title: 'O Alquimista', author: 'Paulo Coelho', status: BookStatus.wishlist),
  ];

  void _addBook(String title, String author, BookStatus status) {
    setState(() {
      _books.add(Book(
        id: DateTime.now().toString(),
        title: title,
        author: author,
        status: status,
      ));
    });
  }

  void _toggleTop5(Book book, int? rank) {
    setState(() {
      if (rank != null) {
        for (var b in _books) {
          if (b.rank == rank) b.rank = null;
        }
      }
      book.rank = rank;
    });
  }

  Future<void> _shareTop5Image() async {
    final bytes = await _imageController.capture();
    if (bytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/meu_top5_livros.png').create();
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Confira o meu Top 5 livros favoritos!');
  }

  @override
  Widget build(BuildContext context) {
    final top5Books = _books.where((b) => b.rank != null).toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ReadRank'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Lidos'),
              Tab(icon: Icon(Icons.bookmark_border), text: 'Desejados'),
              Tab(icon: Icon(Icons.star_outline), text: 'Top 5'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookList(BookStatus.read),
            _buildBookList(BookStatus.wishlist),
            _buildTop5Tab(top5Books),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddBookDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBookList(BookStatus status) {
    final filtered = _books.where((b) => b.status == status).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final book = filtered[index];
        return ListTile(
          title: Text(book.title),
          subtitle: Text(book.author),
          trailing: status == BookStatus.read
              ? PopupMenuButton<int?>(
                  icon: Icon(
                    book.rank != null ? Icons.star : Icons.star_border,
                    color: book.rank != null ? Colors.amber : Colors.grey,
                  ),
                  onSelected: (rank) => _toggleTop5(book, rank),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('Remover do Ranking')),
                    ...List.generate(
                      5,
                      (i) => PopupMenuItem(value: i + 1, child: Text('Posição #${i + 1}')),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildTop5Tab(List<Book> top5Books) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          WidgetsToImage(
            controller: _imageController,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade800, Colors.indigo.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MEU TOP 5 LIVROS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Icon(Icons.auto_stories, color: Colors.amber, size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (top5Books.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Nenhum livro no Top 5 ainda.\nAdicione posições na aba "Lidos".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    ...top5Books.map(
                      (book) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.amber,
                              radius: 16,
                              child: Text(
                                '#${book.rank}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    book.author,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Gerado via ReadRank App',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: top5Books.isNotEmpty ? _shareTop5Image : null,
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar Imagem do Ranking'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    BookStatus selectedStatus = BookStatus.read;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Livro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Autor'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<BookStatus>(
                segments: const [
                  ButtonSegment(value: BookStatus.read, label: Text('Lido')),
                  ButtonSegment(value: BookStatus.wishlist, label: Text('Desejado')),
                ],
                selected: {selectedStatus},
                onSelectionChanged: (set) {
                  setDialogState(() => selectedStatus = set.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _addBook(titleController.text, authorController.text, selectedStatus);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}