import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paciente.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;


class FhirService {
    String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/fhir/Patient';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/fhir/Patient';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8080/fhir/Patient';
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 'http://127.0.0.1:8080/fhir/Patient';
      default:
        return 'http://127.0.0.1:8080/fhir/Patient';
    }
  }
  


  Future<bool> crearPaciente(Paciente paciente) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/fhir+json"},
      body: jsonEncode(paciente.toFhirJson()),
    );
    print("POST status: ${response.statusCode}");
    print("POST body: ${response.body}");
    return response.statusCode == 201 || response.statusCode == 200;
  }


  Future<bool> actualizarPaciente(String id, Paciente paciente) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/fhir+json"},
      body: jsonEncode(paciente.toFhirJson()),
    );
    print('PUT status: ${response.statusCode}');
    print('PUT body: ${response.body}');
    return response.statusCode == 200;
  }


  Future<bool> eliminarPaciente(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    print("DELETE status: ${response.statusCode}");
    print("DELETE body: ${response.body}");
    return response.statusCode == 204 || response.statusCode == 200;

  }


  Future<List<Paciente>> obtenerPacientes() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final entries = (jsonData['entry'] as List<dynamic>?);
      if (entries == null) {
        return [];
      }
      return entries.where((e) => e['resource'] != null).map((e) {
        final resource = e['resource'];
        final id = resource['id'] ?? '';
        final paciente = Paciente.fromFhirJson(resource);
        paciente.idFhir = id;
        return paciente;
      }).toList();
    }
    return [];
  }

}
