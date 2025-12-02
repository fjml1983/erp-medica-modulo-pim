class Paciente {
  String? idFhir;
  String curp;
  String nombre;
  String apellidoPaterno;
  String apellidoMaterno;
  String sexo;
  DateTime fechaNacimiento;
  String calleNumero;
  String colonia;
  String municipio;
  String entidadFederativa;
  String codigoPostal;
  String telefono;
  String correo;
  String responsable;
  String parentesco;
  String tipoSangre;

  Paciente({
    this.idFhir,
    required this.curp,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.sexo,
    required this.fechaNacimiento,
    required this.calleNumero,
    required this.colonia,
    required this.municipio,
    required this.entidadFederativa,
    required this.codigoPostal,
    required this.telefono,
    required this.correo,
    required this.responsable,
    required this.parentesco,
    required this.tipoSangre,
  });

  
  Map<String, dynamic> toFhirJson() {
    final Map<String, dynamic> data = {
      "resourceType": "Patient",
      "identifier": [
        {
          "system": "https://www.gob.mx/curp",
          "value": curp
        }
      ],
      "name": [
        {
          "use": "official",
          "family": apellidoPaterno,
          "given": [nombre]
        },
        {
          "use": "maiden",
          "family": apellidoMaterno
        }
      ],
      "gender": sexo.toLowerCase(),
      "birthDate": "${fechaNacimiento.year.toString().padLeft(4, '0')}-${fechaNacimiento.month.toString().padLeft(2, '0')}-${fechaNacimiento.day.toString().padLeft(2, '0')}",
      "address": [
        {
          "line": [calleNumero],
          "city": colonia,
          "district": municipio,
          "state": entidadFederativa,
          "postalCode": codigoPostal
        }
      ],
      "telecom": [
        {
          "system": "phone",
          "value": telefono
        },
        {
          "system": "email",
          "value": correo
        }
      ],
      "contact": [
        {
          "relationship": [
            {
              "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/v2-0131",
                "code": "C",
                "display": parentesco
              }]
            }
          ],
          "name": {
            "family": responsable,
          }
        }
      ],
      "extension": [
        {
          "url": "http://hl7.org/fhir/StructureDefinition/patient-bloodType",
          "valueString": tipoSangre
        }
      ],
    };

    if (idFhir != null && idFhir!.isNotEmpty) {
      data["id"] = idFhir;
    }

    return data;
  }

  factory Paciente.fromFhirJson(Map<String, dynamic> json) {
    final nameList = (json['name'] as List<dynamic>?) ?? [];
    final addressList = (json['address'] as List<dynamic>?) ?? [];
    final telecomList = (json['telecom'] as List<dynamic>?) ?? [];
    final contactList = (json['contact'] as List<dynamic>?) ?? [];
    String tipoSangre = '';
    if (json['extension'] != null) {
      for (var ext in json['extension']) {
        if (ext['url'] == "http://hl7.org/fhir/StructureDefinition/patient-bloodType") {
          tipoSangre = ext['valueString'] ?? '';
        }
      }
    }
    return Paciente(
      idFhir: json['id'],
      curp: (json['identifier'] as List<dynamic>?)?.firstWhere((id) => id['value'] != null, orElse: () => {'value': ''})['value'] ?? '',
      nombre: nameList.isNotEmpty && nameList[0]['given'] != null ? nameList[0]['given'][0] ?? '' : '',
      apellidoPaterno: nameList.isNotEmpty ? nameList[0]['family'] ?? '' : '',
      apellidoMaterno: nameList.length > 1 ? (nameList[1]['family'] ?? '') : '',
      sexo: json['gender'] ?? '',
      fechaNacimiento: DateTime.tryParse(json['birthDate'] ?? '') ?? DateTime.now(),
      calleNumero: addressList.isNotEmpty && addressList[0]['line'] != null ? addressList[0]['line'][0] ?? '' : '',
      colonia: addressList.isNotEmpty ? addressList[0]['city'] ?? '' : '',
      municipio: addressList.isNotEmpty ? addressList[0]['district'] ?? '' : '',
      entidadFederativa: addressList.isNotEmpty ? addressList[0]['state'] ?? '' : '',
      codigoPostal: addressList.isNotEmpty ? addressList[0]['postalCode'] ?? '' : '',
      telefono: telecomList.isNotEmpty ? telecomList[0]['value'] ?? '' : '',
      correo: telecomList.length > 1 ? telecomList[1]['value'] ?? '' : '',
      responsable: contactList.isNotEmpty && contactList[0]['name'] != null ? contactList[0]['name']['family'] ?? '' : '',
      parentesco: contactList.isNotEmpty && contactList[0]['relationship'] != null
          ? contactList[0]['relationship'][0]['coding'][0]['display'] ?? ''
          : '',
      tipoSangre: tipoSangre,
    );
  }
}