import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(StockTrackerApp());
}

class StockTrackerApp extends StatelessWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/main',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/main': (context) => MainScreen(),
        '/stockDetails': (context) => StockDetailsScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    HomeScreen(),
    WatchlistScreen(),
    NewsfeedScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Login")),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<dynamic>> fetchTrendingStocks() async {
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/stock/symbol?exchange=US&token=ctbiutpr01qvslqulaj0ctbiutpr01qvslqulajg'));
    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchTrendingStocks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading stocks"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(
                      snapshot.data![index]['description'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(snapshot.data![index]['symbol']),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.pushNamed(
                      context, 
                      '/stockDetails', 
                      arguments: snapshot.data![index]
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class StockDetailsScreen extends StatefulWidget {
  const StockDetailsScreen({super.key});

  @override
  _StockDetailsScreenState createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> {
  Future<Map<String, dynamic>> fetchStockQuote(String symbol) async {
    final response = await http.get(Uri.parse(
      'https://finnhub.io/api/v1/quote?symbol=$symbol&token=ctbiutpr01qvslqulaj0ctbiutpr01qvslqulajg'
    ));
    return json.decode(response.body);
  }

  Future<List<dynamic>> fetchCompanyNews(String symbol) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 7));
    final formattedFrom = DateFormat('yyyy-MM-dd').format(from);
    final formattedTo = DateFormat('yyyy-MM-dd').format(now);

    final response = await http.get(Uri.parse(
      'https://finnhub.io/api/v1/company-news?symbol=$symbol&from=$formattedFrom&to=$formattedTo&token=ctbiutpr01qvslqulaj0ctbiutpr01qvslqulajg'
    ));
    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    final stock = ModalRoute.of(context)!.settings.arguments as Map;
    final symbol = stock['symbol'];

    return Scaffold(
      appBar: AppBar(
        title: Text(stock['description']),
        actions: [
          IconButton(
            icon: const Icon(Icons.newspaper),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return FutureBuilder<List<dynamic>>(
                    future: fetchCompanyNews(symbol),
                    builder: (context, newsSnapshot) {
                      if (newsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (newsSnapshot.hasError) {
                        return const Center(child: Text("Error loading news"));
                      } else {
                        return ListView.builder(
                          itemCount: newsSnapshot.data!.length,
                          itemBuilder: (context, index) {
                            final newsItem = newsSnapshot.data![index];
                            return ListTile(
                              title: Text(newsItem['headline']),
                              subtitle: Text(newsItem['source']),
                              onTap: () async {
                                final url = Uri.parse(newsItem['url']);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                            );
                          },
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: fetchStockQuote(symbol),
                builder: (context, quoteSnapshot) {
                  if (quoteSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (quoteSnapshot.hasError) {
                    return const Center(child: Text("Error loading stock data"));
                  } else {
                    final quote = quoteSnapshot.data!;
                    final isPositive = quote['c'] >= quote['pc'];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${quote['c'].toStringAsFixed(2)}', 
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${isPositive ? '+' : ''}${(quote['c'] - quote['pc']).toStringAsFixed(2)} ',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${((quote['c'] - quote['pc']) / quote['pc'] * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: const Text("Chart Placeholder - Implement with real financial charting library"),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stock Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _buildDetailRow('Previous Close', '\$${quote['pc'].toStringAsFixed(2)}'),
                                _buildDetailRow('Open', '\$${quote['o'].toStringAsFixed(2)}'),
                                _buildDetailRow('High', '\$${quote['h'].toStringAsFixed(2)}'),
                                _buildDetailRow('Low', '\$${quote['l'].toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> removeStockFromWatchlist(String symbol) async {
    if (user != null) {
      await _firestore
          .collection('watchlists')
          .doc(user!.uid)
          .collection('stocks')
          .doc(symbol)
          .delete();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Watchlist")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('watchlists')
            .doc(user!.uid)
            .collection('stocks')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading watchlist"));
          } else if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No stocks in your watchlist"));
          } else {
            return ListView(
              children: snapshot.data!.docs.map((doc) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(doc['symbol']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removeStockFromWatchlist(doc['symbol']),
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}

class NewsfeedScreen extends StatelessWidget {
  const NewsfeedScreen({super.key});

  Future<List<dynamic>> fetchStockNews() async {
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/news?category=general&token=ctbiutpr01qvslqulaj0ctbiutpr01qvslqulajg'));
    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock News")),
      body: FutureBuilder<List<dynamic>>(
        future: fetchStockNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading news"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final newsItem = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(
                      newsItem['headline'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(newsItem['source']),
                    onTap: () async {
                      final url = Uri.parse(newsItem['url']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}