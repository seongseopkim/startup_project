import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiDictionaryScreen extends StatefulWidget {
  const GeminiDictionaryScreen({super.key});

  @override
  State<GeminiDictionaryScreen> createState() => _GeminiDictionaryScreenState();
}

class _GeminiDictionaryScreenState extends State<GeminiDictionaryScreen> {
  final TextEditingController _keywordController = TextEditingController();
  String? _answer;
  bool _isLoading = false;

  final List<String> stockTerms = [
    "PER",
    "EPS",
    "PBR",
    "ROE",
    "시가총액",
    "배당률",
    "유상증자",
    "무상증자",
    "상장",
    "상장폐지",
    "공모주",
    "우선주",
    "보통주",
    "ETF",
    "ETN",
    "공매도",
    "호가",
    "매수",
    "매도",
    "매물대",
    "손절",
    "익절",
    "분할매수",
    "동일인한도",
    "상한가",
    "하한가",
    "테마주",
    "우량주",
    "잡주",
    "차트"
  ];

  Future<void> _askGeminiWithKeyword(String keyword) async {
    setState(() {
      _isLoading = true;
      _answer = null;
    });

    final response = await http.post(
      Uri.parse("http://127.0.0.1:3050/gemini/term-explanation"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"term": keyword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _answer = data["answer"];
        _isLoading = false;
      });
    } else {
      setState(() {
        _answer = "❗ Gemini 응답 실패: ${response.statusCode}";
        _isLoading = false;
      });
    }
  }

  void _askGemini() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty) {
      _askGeminiWithKeyword(keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("용어 사전", style: TextStyle(color: Colors.purpleAccent)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "궁금한 용어를 검색하세요",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.purpleAccent),
                    onPressed: _askGemini,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stockTerms
                    .map((term) => ActionChip(
                          label: Text(term),
                          backgroundColor: Colors.grey[700],
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () => _askGeminiWithKeyword(term),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_answer != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Text(
                      _answer!,
                      style: const TextStyle(color: Colors.purpleAccent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
