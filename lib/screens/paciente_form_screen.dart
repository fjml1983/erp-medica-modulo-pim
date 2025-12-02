import 'package:flutter/material.dart';
import '../models/paciente.dart';
import '../services/fhir_service.dart';
import '../services/db_helper.dart';

class PacienteFormScreen extends StatefulWidget {
  final Paciente? paciente;
  final Function()? onSaved;

  const PacienteFormScreen({Key? key, this.paciente, this.onSaved}) : super(key: key);

  @override
  State<PacienteFormScreen> createState() => _PacienteFormScreenState();
}

class _PacienteFormScreenState extends State<PacienteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _curpController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoPController = TextEditingController();
  final _apellidoMController = TextEditingController();
  final _fechaController = TextEditingController();
  final _calleNumeroController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _responsableController = TextEditingController();
  final _parentescoController = TextEditingController();

  final List<String> tiposSangre = [
    "Seleccionar", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"
  ];
  String _tipoSangre = "Seleccionar";


  bool _cargandoEntidades = false;
  bool _cargandoMunicipios = false;
  bool _cargandoCP = false;
  bool _saving = false;

  String _sexo = "Seleccionar";
  String? _entidadSeleccionada;       
  String? _municipioSeleccionado;   
  String? _codigoPostalSeleccionado;  


  String? _entidadRaw;
  String? _municipioRaw;
  String? _cpRaw;


  List<Map<String, dynamic>> entidades = [];      
  List<Map<String, dynamic>> municipios = [];     
  List<Map<String, dynamic>> codigosPostales = [];

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    if (widget.paciente != null) {
      final p = widget.paciente!;
      _curpController.text = p.curp;
      _nombreController.text = p.nombre;
      _apellidoPController.text = p.apellidoPaterno;
      _apellidoMController.text = p.apellidoMaterno;
      _fechaController.text = p.fechaNacimiento.toIso8601String().substring(0, 10);
      _sexo = p.sexo;
      _calleNumeroController.text = p.calleNumero;
      _coloniaController.text = p.colonia;
      _telefonoController.text = p.telefono;
      _correoController.text = p.correo;
      _responsableController.text = p.responsable;
      _parentescoController.text = p.parentesco;
      _tipoSangre = p.tipoSangre;

   
      _entidadRaw = p.entidadFederativa;
      _municipioRaw = p.municipio;
      _cpRaw = p.codigoPostal;

     
      final cpOriginal = _cpRaw;

    
      await cargarEntidades();

      final mappedEntidadClave = _mapEntidadValueToClave(_entidadRaw);
      if (mappedEntidadClave != null) {
        setState(() => _entidadSeleccionada = mappedEntidadClave);
      
        await cargarMunicipios(_entidadSeleccionada!, preserveSelection: true);

        
        final mappedMunicipioClave = _mapMunicipioValueToClave(_municipioRaw);
        if (mappedMunicipioClave != null) {
          setState(() => _municipioSeleccionado = mappedMunicipioClave);
          
          await cargarCodigosPostales(_municipioSeleccionado!, preselectCp: cpOriginal);
        } else {
          
          if (_municipioSeleccionado != null && _municipioSeleccionado!.isNotEmpty) {
            await cargarCodigosPostales(_municipioSeleccionado!, preselectCp: cpOriginal);
          } else {
            
            debugPrint('initLoad: no se mapeó municipioRaw=$_municipioRaw a una clave válida');
          }
        }
      } else {
        
        debugPrint('initLoad: no se mapeó entidadRaw=$_entidadRaw a una clave válida');
      }

      debugPrint('Preselecciones al iniciar: entidadRaw=$_entidadRaw -> entidadSeleccionada=$_entidadSeleccionada, municipioRaw=$_municipioRaw -> municipioSeleccionado=$_municipioSeleccionado, cpRaw=$_cpRaw -> cpSeleccionado=$_codigoPostalSeleccionado');
    } else {
      await cargarEntidades();
    }
  }

  @override
  void dispose() {
    _curpController.dispose();
    _nombreController.dispose();
    _apellidoPController.dispose();
    _apellidoMController.dispose();
    _fechaController.dispose();
    _calleNumeroController.dispose();
    _coloniaController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _responsableController.dispose();
    _parentescoController.dispose();
    super.dispose();
  }


  Future<void> cargarEntidades() async {
    setState(() => _cargandoEntidades = true);
    try {
      final rows = await DBHelper().getEntidades();
      entidades = rows.map((e) => {
        'clave': (e['clave'] ?? e['c_estado'] ?? e['id'] ?? '').toString(),
        'nombre': (e['nombre'] ?? '').toString(),
      }).toList();

      if (_entidadRaw != null && _entidadRaw!.isNotEmpty) {
        final mapped = _mapEntidadValueToClave(_entidadRaw);
        if (mapped != null) {
          _entidadSeleccionada = mapped;
        }
      }

      
      if (_entidadSeleccionada != null &&
          !entidades.any((x) => x['clave'] == _entidadSeleccionada)) {
        _entidadSeleccionada = null;
      }
    } catch (e) {
      debugPrint('Error al cargar entidades: $e');
    } finally {
      if (mounted) setState(() => _cargandoEntidades = false);
    }
  }

  
  Future<void> cargarMunicipios(String claveEntidad, {bool preserveSelection = false}) async {
    setState(() {
      _cargandoMunicipios = true;
      municipios = [];
      codigosPostales = [];
      if (!preserveSelection) {
        
        _municipioSeleccionado = null;
        _codigoPostalSeleccionado = null;
      }
    });
    try {
      final rows = await DBHelper().getMunicipios(claveEntidad);

      municipios = rows.map((m) {
        final nombre = (m['nombre'] ?? m['d_mnpio'] ?? '').toString();
        String cMnpio3;
        if (m.containsKey('c_mnpio') && m['c_mnpio'] != null && m['c_mnpio'].toString().isNotEmpty) {
          cMnpio3 = m['c_mnpio'].toString().padLeft(3, '0');
        } else {
          final raw = (m['clave'] ?? m['id'] ?? '').toString();
          cMnpio3 = raw.length >= 3 ? raw.substring(raw.length - 3) : raw.padLeft(3, '0');
        }
        return {'c_mnpio': cMnpio3, 'nombre': nombre};
      }).toList();

      
      municipios.sort((a, b) => (a['nombre'] ?? '').compareTo(b['nombre'] ?? ''));

      
      if (preserveSelection && (_municipioSeleccionado == null || _municipioSeleccionado!.isEmpty) && _municipioRaw != null && _municipioRaw!.isNotEmpty) {
        final mMapped = _mapMunicipioValueToClave(_municipioRaw);
        if (mMapped != null && municipios.any((m) => m['c_mnpio'] == mMapped)) {
          _municipioSeleccionado = mMapped;
        }
      }

      
      if (!preserveSelection &&
          _municipioSeleccionado != null &&
          !municipios.any((m) => m['c_mnpio'] == _municipioSeleccionado)) {
        _municipioSeleccionado = null;
      }
    } catch (e) {
      debugPrint('Error al cargar municipios: $e');
    } finally {
      if (mounted) setState(() => _cargandoMunicipios = false);
    }
  }

  
  Future<void> cargarCodigosPostales(String cMnpio3, {String? preselectCp}) async {
    if (_entidadSeleccionada == null) return;
    setState(() {
      _cargandoCP = true;
      codigosPostales = [];
      
      if (preselectCp == null) {
        _codigoPostalSeleccionado = null;
      }
    });

    try {
      final rows = await DBHelper().getCodigosPostalesSmart(
        cEstado: _entidadSeleccionada!,
        cMnpio3: cMnpio3.padLeft(3, '0'),
        municipioNombre: (() {
          try {
            final m = municipios.firstWhere((x) => x['c_mnpio'] == cMnpio3 || x['clave'] == cMnpio3);
            return m['nombre'];
          } catch (_) {
            return null;
          }
        })(),
      );

      
      final unique = <String>{};
      for (final r in rows) {
        final raw = (r['d_codigo'] ?? r['codigo'] ?? r['cp'] ?? '').toString().trim();
        if (raw.isNotEmpty) unique.add(raw);
      }

      
      final lista = unique.map((cp) => {'d_codigo': cp}).toList()
        ..sort((a, b) => (a['d_codigo'] ?? '').compareTo(b['d_codigo'] ?? ''));

      setState(() {
        codigosPostales = lista;
        
        if (preselectCp != null && unique.contains(preselectCp)) {
          _codigoPostalSeleccionado = preselectCp;
        }
      });

      debugPrint('CPs únicos: ${codigosPostales.length} para estado=${_entidadSeleccionada!} mnpio=$cMnpio3 (preselect=$preselectCp)');
      debugPrint('Estado seleccionado: ${_entidadSeleccionada}, Municipio seleccionado: ${_municipioSeleccionado}, CP seleccionado: ${_codigoPostalSeleccionado}');
    } catch (e, st) {
      debugPrint('Error al cargar CPs: $e\n$st');
    } finally {
      if (mounted) setState(() => _cargandoCP = false);
    }
  }


  String _nombreEntidadDesdeClave(String? clave) {
    if (clave == null || clave.isEmpty) return '';
    try {
      final e = entidades.firstWhere((x) => (x['clave'] ?? '').toString() == clave);
      return (e['nombre'] ?? clave).toString();
    } catch (_) {
      return clave;
    }
  }

  String _nombreMunicipioDesdeClave(String? cMnpio) {
    if (cMnpio == null || cMnpio.isEmpty) return '';
    try {
      final m = municipios.firstWhere((x) => (x['c_mnpio'] ?? '').toString() == cMnpio);
      return (m['nombre'] ?? cMnpio).toString();
    } catch (_) {
      return cMnpio;
    }
  }

  
  String? _mapEntidadValueToClave(String? value) {
    if (value == null || value.isEmpty) return null;

    
    try {
      if (entidades.any((e) => (e['clave'] ?? '').toString() == value)) {
        return value;
      }
    } catch (_) {}

    
    try {
      final found = entidades.firstWhere((e) => ((e['nombre'] ?? '').toString().toLowerCase() == value.toLowerCase()));
      return (found['clave'] ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  
  String? _mapMunicipioValueToClave(String? value) {
    if (value == null || value.isEmpty) return null;

    
    try {
      if (municipios.any((m) => (m['c_mnpio'] ?? '').toString() == value)) {
        return value;
      }
    } catch (_) {}

    
    try {
      final found = municipios.firstWhere((m) => ((m['nombre'] ?? '').toString().toLowerCase() == value.toLowerCase()));
      return (found['c_mnpio'] ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      
      final entidadNombre = _nombreEntidadDesdeClave(_entidadSeleccionada);
      final municipioNombre = _nombreMunicipioDesdeClave(_municipioSeleccionado);

      final paciente = Paciente(
        idFhir: widget.paciente?.idFhir,
        curp: _curpController.text,
        nombre: _nombreController.text,
        apellidoPaterno: _apellidoPController.text,
        apellidoMaterno: _apellidoMController.text,
        sexo: _sexo,
        fechaNacimiento: DateTime.parse(_fechaController.text),
        calleNumero: _calleNumeroController.text,
        colonia: _coloniaController.text,
        
        municipio: municipioNombre.isNotEmpty ? municipioNombre : (_municipioSeleccionado ?? ''),
        entidadFederativa: entidadNombre.isNotEmpty ? entidadNombre : (_entidadSeleccionada ?? ''),
        codigoPostal: _codigoPostalSeleccionado ?? '',
        telefono: _telefonoController.text,
        correo: _correoController.text,
        responsable: _responsableController.text,
        parentesco: _parentescoController.text,
        tipoSangre: _tipoSangre,
      );

      final ok = widget.paciente == null
          ? await FhirService().crearPaciente(paciente)
          : await FhirService().actualizarPaciente(widget.paciente!.idFhir!, paciente);

      if (!mounted) return;

      if (ok) {
        widget.onSaved?.call();
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar/actualizar el paciente en HAPI FHIR')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.paciente != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FA),
      appBar: AppBar(
        title: Text(isEditing ? "Editar Paciente" : "Agregar Paciente"),
        backgroundColor: Colors.deepPurple[400],
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Card(
          elevation: 7,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle("Datos Personales"),

                  TextFormField(
                    controller: _curpController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "CURP",
                      prefixIcon: const Icon(Icons.badge, color: Colors.purple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.length != 18) {
                        return "El CURP debe tener 18 caracteres";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: "Nombre(s)",
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _apellidoPController,
                          decoration: InputDecoration(
                            labelText: "Apellido Paterno",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _apellidoMController,
                          decoration: InputDecoration(
                            labelText: "Apellido Materno",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fechaController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Fecha de Nacimiento (YYYY-MM-DD)",
                      prefixIcon: const Icon(Icons.cake, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        _fechaController.text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _sexo,
                    items: const [
                      DropdownMenuItem(value: "Seleccionar", child: Text("Seleccionar")),
                      DropdownMenuItem(value: "male", child: Text("Masculino")),
                      DropdownMenuItem(value: "female", child: Text("Femenino")),
                    ],
                    onChanged: (value) => setState(() => _sexo = value ?? "Seleccionar"),
                    decoration: InputDecoration(
                      labelText: "Sexo",
                      prefixIcon: const Icon(Icons.transgender, color: Colors.pink),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v == "Seleccionar") ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _tipoSangre,
                    items: tiposSangre.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) => setState(() => _tipoSangre = value ?? "Seleccionar"),
                    decoration: InputDecoration(
                      labelText: "Tipo de Sangre",
                      prefixIcon: const Icon(Icons.bloodtype, color: Colors.redAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.isEmpty || value == "Seleccionar"
                        ? "Campo obligatorio"
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle("Dirección"),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _entidadSeleccionada,
                    items: entidades.map((e) => DropdownMenuItem<String>(
                      value: e['clave'],
                      child: Text(e['nombre'] ?? '', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: _cargandoEntidades ? null : (value) async {
                      if (value != null) {
                        setState(() {
                          _entidadSeleccionada = value;
                          _municipioSeleccionado = null;
                          _codigoPostalSeleccionado = null;
                          municipios = [];
                          codigosPostales = [];
                        });
                        await cargarMunicipios(value);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: _cargandoEntidades ? 'Cargando entidades...' : 'Entidad Federativa',
                      prefixIcon: const Icon(Icons.map, color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _municipioSeleccionado,
                    items: municipios.map((m) => DropdownMenuItem<String>(
                      value: m['c_mnpio'],
                      child: Text(m['nombre'] ?? '', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (_entidadSeleccionada != null &&
                            !_cargandoMunicipios &&
                            municipios.isNotEmpty)
                        ? (value) async {
                            if (value != null) {
                              setState(() {
                                _municipioSeleccionado = value;
                                _codigoPostalSeleccionado = null;
                                codigosPostales = [];
                              });
                              await cargarCodigosPostales(value);
                            }
                          }
                        : null,
                    decoration: InputDecoration(
                      labelText: _cargandoMunicipios
                          ? 'Cargando municipios...'
                          : (_entidadSeleccionada == null
                              ? 'Primero selecciona una entidad'
                              : 'Municipio'),
                      prefixIcon: const Icon(Icons.location_city, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _codigoPostalSeleccionado,
                    items: codigosPostales.map((cp) => DropdownMenuItem<String>(
                      value: cp['d_codigo'],
                      child: Text(cp['d_codigo'] ?? '', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (_municipioSeleccionado != null && !_cargandoCP && codigosPostales.isNotEmpty)
                        ? (value) {
                            if (value != null) {
                              setState(() => _codigoPostalSeleccionado = value);
                            }
                          }
                        : null,
                    decoration: InputDecoration(
                      labelText: _cargandoCP
                          ? 'Cargando códigos postales...'
                          : (_municipioSeleccionado == null ? 'Primero selecciona un municipio' : 'Código Postal'),
                      prefixIcon: const Icon(Icons.numbers, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _calleNumeroController,
                    decoration: InputDecoration(
                      labelText: "Calle y Número",
                      prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coloniaController,
                    decoration: InputDecoration(
                      labelText: "Colonia",
                      prefixIcon: const Icon(Icons.home, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle("Contacto"),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: InputDecoration(
                      labelText: "Teléfono",
                      prefixIcon: const Icon(Icons.phone, color: Colors.black),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _correoController,
                    decoration: InputDecoration(
                      labelText: "Correo Electrónico",
                      prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return "Correo inválido";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.deepPurple,
                      elevation: 6,
                    ),
                    onPressed: _saving ? null : guardarPaciente,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditing ? "Actualizar" : "Guardar",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
