import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final String apiKey = '73ae9fc12b8b652162dc2dcd';
  String fromCurrency = 'USD';
  String toCurrency = 'INR';
  String amount = ''; 
  double result = 0.0;
  double conversionRate = 0.0;
  List<String> currencies = [];
  bool isLoading = false;
  bool isFetchingCurrencies = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    fetchSupportedCurrencies();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchSupportedCurrencies() async {
    setState(() {
      isFetchingCurrencies = true;
    });

    try {
      final String apiUrl = 'https://v6.exchangerate-api.com/v6/$apiKey/codes';
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            currencies = (data['supported_codes'] as List)
                .map((code) => code[0] as String)
                .toList();
            isFetchingCurrencies = false;
          });
        } else {
          throw Exception('API error: ${data['error-type']}');
        }
      } else {
        throw Exception('Failed to load supported currencies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching supported currencies: $e');
      setState(() {
        isFetchingCurrencies = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching supported currencies: $e')),
      );
    }
  }

  Future<void> fetchConversionRate() async {
    if (amount.isEmpty || double.parse(amount) <= 0) return;

    setState(() {
      isLoading = true;
    });

    try {
      final String apiUrl =
          'https://v6.exchangerate-api.com/v6/$apiKey/pair/$fromCurrency/$toCurrency/$amount';

      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            conversionRate = data['conversion_rate'];
            result = data['conversion_result'];
            isLoading = false;
          });
        } else {
          throw Exception('API error: ${data['error-type']}');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void convertCurrency() {
    if (amount.isNotEmpty && double.parse(amount) > 0) {
      fetchConversionRate();
    }
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'C') {
        amount = '';
      } else if (key == '<') {
        if (amount.isNotEmpty) {
          amount = amount.substring(0, amount.length - 1);
        }
      } else if (amount.length < 10) {
        amount += key;
      }
    });
  }

  void _swapCurrencies() {
    setState(() {
      String temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Currency Swap'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      amount.isEmpty ? '0.00' : amount,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isFetchingCurrencies)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: fromCurrency,
                        items: currencies.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            fromCurrency = newValue!;
                          });
                        },
                        isExpanded: true,
                        dropdownColor: Colors.grey.shade900,
                      ),
                    ),
                    IconButton(
                      onPressed: _swapCurrencies,
                      icon: Icon(Icons.swap_horiz, color: Colors.red),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: toCurrency,
                        items: currencies.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            toCurrency = newValue!;
                          });
                        },
                        isExpanded: true,
                        dropdownColor: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Result Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Converted Amount',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result == 0 ? '0.00' : '${result.toStringAsFixed(2)} $toCurrency',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Convert Button
              ElevatedButton(
                onPressed: convertCurrency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Convert',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),

              // Numpad
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3, // Fixed height for numpad
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  padding: const EdgeInsets.all(10),
                  children: [
                    '1', '2', '3',
                    '4', '5', '6',
                    '7', '8', '9',
                    'C', '0', '<',
                  ].map((key) {
                    return GestureDetector(
                      onTap: () => _onKeyPressed(key),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Center(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}