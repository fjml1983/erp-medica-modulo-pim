import 'package:flutter/material.dart';
import '../models/paciente.dart';
import '../services/fhir_service.dart';
import '../widgets/paciente_card.dart';
import 'paciente_form_screen.dart';

class PacienteListScreen extends StatefulWidget {
  @override
  _PacienteListScreenState createState() => _PacienteListScreenState();
}

class _PacienteListScreenState extends State<PacienteListScreen> {
  List<Paciente> pacientes = [];
  List<Paciente> pacientesFiltrados = [];
  bool loading = true;
  final TextEditingController _buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarPacientes();
    _buscarController.addListener(_filtrarPacientes);
  }

  Future<void> cargarPacientes() async {
    setState(() => loading = true);
    pacientes = await FhirService().obtenerPacientes();
    pacientesFiltrados = pacientes;
    setState(() => loading = false);
  }

  void _filtrarPacientes() {
    String query = _buscarController.text.toLowerCase();
    setState(() {
      pacientesFiltrados = pacientes.where((p) {
        return p.nombre.toLowerCase().contains(query) ||
            p.curp.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _agregarPaciente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PacienteFormScreen(onSaved: cargarPacientes),
      ),
    );
  }

  void _editarPaciente(Paciente paciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PacienteFormScreen(
          paciente: paciente,
          onSaved: cargarPacientes,
        ),
      ),
    );
  }

 Future<void> _eliminarPaciente(Paciente paciente) async {
  if (paciente.idFhir == null) return;

  
  bool? confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Confirmar eliminación"),
      content: Text(
        "¿Desea eliminar al paciente seleccionado?\nUna vez borrado no es posible recuperarlo de nuevo.",
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          child: Text("Cancelar"),
          onPressed: () => Navigator.pop(ctx, false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text("Borrar"),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );

  
  if (confirmar == true) {
    bool ok = await FhirService().eliminarPaciente(paciente.idFhir!);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paciente eliminado")));
      cargarPacientes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar paciente")));
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pacientes FHIR")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _buscarController,
              decoration: InputDecoration(
                labelText: "Buscar por nombre o CURP",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : pacientesFiltrados.isEmpty
                    ? Center(child: Text("No hay pacientes registrados"))
                    : ListView.builder(
                        itemCount: pacientesFiltrados.length,
                        itemBuilder: (context, idx) {
                          final paciente = pacientesFiltrados[idx];
                          return PacienteCard(
                            paciente: paciente,
                            onEdit: () => _editarPaciente(paciente),
                            onDelete: () => _eliminarPaciente(paciente),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _agregarPaciente,
      ),
    );
  }
}