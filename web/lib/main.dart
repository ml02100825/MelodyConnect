import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;

const baseUrl = String.fromEnvironment("API_BASE_URL", defaultValue: "http://10.0.2.2:8080");

Future<String> fetchHello() async {
  final res = await http.get(Uri.parse("$baseUrl/api/hello"));
  if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}");
  return json.decode(res.body).toString();
}

void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Flutter x Spring")),
        body: FutureBuilder(
          future: fetchHello(),
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (s.hasError) return Center(child: Text("Error: ${s.error}"));
            return Center(child: Text("API: ${s.data}"));
          },
        ),
      ),
    );
  }
}
