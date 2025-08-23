import 'package:flutter/material.dart';
import 'package:amplitude_experiment/amplitude_experiment.dart';

void main() {
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
      // Replace with your actual API key
      _experimentClient = Experiment.initialize(
        '9f0e2018a718d88713eda6429a467091',
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
        _statusMessage = 'Error: $e';
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fetchVariants,
                      child: const Text('Fetch Variants'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading || _experimentClient == null
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
