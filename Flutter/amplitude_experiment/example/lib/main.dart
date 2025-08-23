import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplitude_experiment/amplitude_experiment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional)
  try {
    await dotenv.load(fileName: ".env");
    print('Loaded .env file successfully');
  } catch (e) {
    // .env file is optional, will use default if not found
    print('Note: .env file not found or could not be loaded: $e');
    print('You can create a .env file with: AMPLITUDE_API_KEY=your_key_here');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amplitude Experiment Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Amplitude Experiment Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ExperimentClient? _experimentClient;
  Variants _variants = {};
  bool _isLoading = false;
  String _statusMessage = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _initializeExperiment();
  }

  Future<void> _initializeExperiment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing...';
    });

    try {
      // Initialize the Experiment client
      // Get API key from environment variables or use a default for testing
      final apiKey = dotenv.env['AMPLITUDE_API_KEY'] ?? 'YOUR_API_KEY_HERE';
      
      print('Using API key: ${apiKey.substring(0, 10)}...');  // Show first 10 chars for debugging
      
      if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
        // Show warning but allow app to run
        setState(() {
          _statusMessage = 'Warning: No valid API key found. Create .env file with AMPLITUDE_API_KEY=your_key';
        });
        // Don't continue with invalid key
        _experimentClient = null;
        return;
      }
      
      _experimentClient = Experiment.initialize(
        apiKey,
        config: const ExperimentConfig(
          debug: true,
          fetchOnStart: true,
        ),
      );

      // Set user context
      _experimentClient!.setUser(
        const ExperimentUser(
          userId: 'test_user_123',
          deviceId: 'test_device_456',
          userProperties: {
            'plan': 'premium',
            'accountAge': 30,
          },
        ),
      );

      // Start the client
      await _experimentClient!.start();

      setState(() {
        _statusMessage = 'Client initialized successfully';
      });

      // Fetch variants
      await _fetchVariants();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Initialization failed: $e';
      });
      // Log the full error for debugging
      print('Initialization error: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVariants() async {
    if (_experimentClient == null) {
      setState(() {
        _statusMessage = 'Client not initialized';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching variants...';
    });

    try {
      final variants = await _experimentClient!.fetch();
      
      setState(() {
        _variants = variants;
        _isLoading = false;
        _statusMessage = 'Variants fetched: ${variants.length} variants';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error fetching variants: $e';
      });
    }
  }

  Widget _buildVariantCard(String key, Variant variant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variant.value != null)
              Text('Value: ${variant.value}'),
            if (variant.payload != null)
              Text('Payload: ${variant.payload}'),
            if (variant.expKey != null)
              Text('Experiment: ${variant.expKey}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Status: $_statusMessage',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_experimentClient == null)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _initializeExperiment,
                        child: const Text('Retry Initialize'),
                      )
                    else ...[
                      ElevatedButton(
                        onPressed: _isLoading ? null : _fetchVariants,
                        child: const Text('Fetch Variants'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                await _experimentClient!.clear();
                                setState(() {
                                  _variants = {};
                                  _statusMessage = 'Variants cleared';
                                });
                              },
                        child: const Text('Clear Variants'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_variants.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No variants available'),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: _variants.entries
                    .map((entry) => _buildVariantCard(entry.key, entry.value))
                    .toList(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Example of getting a specific variant
          if (_experimentClient == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Client not initialized'),
              ),
            );
            return;
          }
          
          final buttonColorVariant = _experimentClient!.variant(
            'button_color',
            fallback: const Variant(value: 'blue'),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Button color variant: ${buttonColorVariant.value}',
              ),
            ),
          );
        },
        tooltip: 'Get Variant',
        child: const Icon(Icons.science),
      ),
    );
  }

  @override
  void dispose() {
    _experimentClient?.dispose();
    super.dispose();
  }
}
