import 'package:flutter/material.dart';
import '../models/paciente.dart';

class PacienteCard extends StatelessWidget {
  final Paciente paciente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PacienteCard({
    Key? key,
    required this.paciente,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700], size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${paciente.nombre} ${paciente.apellidoPaterno} ${paciente.apellidoMaterno}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.green),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            SizedBox(height: 6),
            Divider(),
            Row(
              children: [
                Icon(Icons.cake, size: 18, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  "${_edad(paciente.fechaNacimiento)} años",
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(width: 14),
                Icon(Icons.phone, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(
                  paciente.telefono,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(width: 14),
                Icon(Icons.bloodtype, size: 18, color: Colors.redAccent),
                SizedBox(width: 4),
                Text(
                  paciente.tipoSangre,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.badge, size: 18, color: Colors.purple),
                SizedBox(width: 4),
                Text("CURP: ${paciente.curp}", style: TextStyle(fontSize: 15)),
              ],
            ),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home, size: 18, color: Colors.green[700]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "${paciente.calleNumero}, ${paciente.colonia}, ${paciente.municipio}, ${paciente.entidadFederativa}",
                    style: TextStyle(fontSize: 15),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _edad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }
}