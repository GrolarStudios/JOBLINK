import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const _blue = Color(0xFF2555D9);
const _ink = Color(0xFF18243B);
const _bg = Color(0xFFF5F7FC);

class EmpleoPage extends StatefulWidget {
  const EmpleoPage({super.key});
  @override
  State<EmpleoPage> createState() => _EmpleoPageState();
}

class _Job {
  final String title, company, city, salary, type;
  final bool basic, firstJob;
  const _Job(this.title,this.company,this.city,this.salary,this.type,{this.basic=true,this.firstJob=true});
}

class _EmpleoPageState extends State<EmpleoPage> {
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();
  bool logged = false, register = false, premium = false, companyAccount = false;
  int nextJobId = 100;
  final List<_Job> companyJobs = [];
  final Set<int> companyCandidates = {};
  final companyName = TextEditingController();
  final jobTitle = TextEditingController(), jobCity = TextEditingController(), jobSalary = TextEditingController(), jobType = TextEditingController();
  String name = 'Alex', section = 'Inicio', search = '', filter = 'Todas';
  final email = TextEditingController(), password = TextEditingController(), fullName = TextEditingController();
  final Set<int> applied = {}, saved = {};
  final List<_Job> jobs = [
    _Job('Auxiliar administrativo','Empresa Horizonte','Guadalajara, Jalisco','\$9,000–\$11,000','Tiempo completo'),
    _Job('Asesor de atención al cliente','Conecta MX','Remoto','\$8,500–\$10,000','Remoto'),
    _Job('Practicante de marketing','Nexo Creativo','Zapopan, Jalisco','\$6,000–\$8,000','Medio tiempo'),
    _Job('Desarrollador junior','Nova Tech','Remoto','\$14,000–\$18,000','Tiempo completo',basic:false),
    _Job('Analista de datos trainee','Impulso Digital','Ciudad de México','\$12,000–\$15,000','Híbrido',basic:false),
    _Job('Asistente de recursos humanos','Talento Joven','Monterrey, Nuevo León','\$10,000–\$12,000','Tiempo completo'),
    _Job('Diseñador UX junior','Estudio Pixel','Remoto','\$13,000–\$17,000','Remoto',basic:false),
  ];
  static const _storageKey = 'joblink_demo_local_v1';
  String accountKey = '';
  Map<String, dynamic> _accounts = {};
  bool _loaded = false;

  @override
  void initState() { super.initState(); _restore(); }

  Map<String, dynamic> _jobData(_Job j) => {
    'title': j.title, 'company': j.company, 'city': j.city,
    'salary': j.salary, 'type': j.type, 'basic': j.basic, 'firstJob': j.firstJob,
  };
  _Job _fromJob(Map<String, dynamic> m) => _Job(
    '${m['title'] ?? ''}', '${m['company'] ?? ''}', '${m['city'] ?? ''}',
    '${m['salary'] ?? ''}', '${m['type'] ?? ''}',
    basic: m['basic'] != false, firstJob: m['firstJob'] != false,
  );
  String _key(String mail, bool company) => '${company ? 'empresa' : 'joven'}:${mail.trim().toLowerCase()}';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        _accounts = Map<String, dynamic>.from(data['accounts'] as Map? ?? {});
        final entries = (data['publications'] as List? ?? []);
        for (final item in entries) {
          final m = Map<String, dynamic>.from(item as Map);
          final j = _fromJob(m);
          companyJobs.add(j);
          jobs.add(j);
        }
        accountKey = '${data['active'] ?? ''}';
        if (accountKey.isNotEmpty && _accounts.containsKey(accountKey)) {
          _activateAccount(accountKey);
        }
      }
    } catch (e) { debugPrint('Joblink: no se pudo recuperar el cache local: $e'); }
    if (mounted) setState(() => _loaded = true);
  }

  void _activateAccount(String key) {
    final data = Map<String, dynamic>.from(_accounts[key] as Map);
    accountKey = key;
    name = '${data['name'] ?? 'Usuario'}';
    companyAccount = data['company'] == true;
    premium = data['premium'] == true;
    email.text = '${data['email'] ?? ''}';
    applied..clear()..addAll((data['applied'] as List? ?? []).whereType<num>().map((v) => v.toInt()).where((v) => v >= 0 && v < jobs.length));
    saved..clear()..addAll((data['saved'] as List? ?? []).whereType<num>().map((v) => v.toInt()).where((v) => v >= 0 && v < jobs.length));
    logged = true;
    section = 'Inicio';
  }

  Future<void> _persist() async {
    if (!_loaded) return;
    if (accountKey.isNotEmpty && _accounts.containsKey(accountKey)) {
      final a = Map<String, dynamic>.from(_accounts[accountKey] as Map);
      a['name'] = name; a['premium'] = premium;
      a['applied'] = applied.toList(); a['saved'] = saved.toList();
      _accounts[accountKey] = a;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode({
      'active': logged ? accountKey : '',
      'accounts': _accounts,
      'publications': companyJobs.map(_jobData).toList(),
    }));
  }

  void _signIn() {
    final mail = email.text.trim().toLowerCase();
    if (!mail.contains('@') || password.text.length < 6) {
      notice('Ingresa un correo válido y una contraseña de al menos 6 caracteres'); return;
    }
    final key = _key(mail, companyAccount);
    if (register || !_accounts.containsKey(key)) {
      // Acceso simulado: se crea un perfil local si no existe.
      final display = companyAccount
          ? (companyName.text.trim().isNotEmpty ? companyName.text.trim() : 'Empresa demo')
          : (fullName.text.trim().isNotEmpty ? fullName.text.trim() : mail.split('@').first);
      _accounts[key] = {'name': display, 'email': mail, 'company': companyAccount,
        'premium': false, 'applied': <int>[], 'saved': <int>[]};
    }
    setState(() => _activateAccount(key));
    password.clear();
    _persist();
    notice('Sesión local de demostración. No se verifica contraseña.');
  }

  @override
  void dispose(){email.dispose();password.dispose();fullName.dispose();companyName.dispose();jobTitle.dispose();jobCity.dispose();jobSalary.dispose();jobType.dispose();super.dispose();}
  void notice(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Widget panel({required Widget child})=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE7EBF3))),child:child);
  Widget button(String label,VoidCallback onTap,{bool outline=false})=>OutlinedButton(onPressed:onTap,style:OutlinedButton.styleFrom(backgroundColor:outline?Colors.white:_blue,foregroundColor:outline?_blue:Colors.white,side:BorderSide(color:outline?_blue:Colors.transparent),padding:const EdgeInsets.symmetric(horizontal:20,vertical:17),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),child:Text(label));
  @override
  Widget build(BuildContext context){return Theme(data:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:_blue),scaffoldBackgroundColor:_bg),child:!_loaded?const Scaffold(body:Center(child:CircularProgressIndicator())):logged?_home():_login());}
  Widget _login()=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:panel(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Icon(Icons.trending_up_rounded,size:54,color:_blue),const SizedBox(height:12),const Text('Joblink',textAlign:TextAlign.center,style:TextStyle(fontSize:31,fontWeight:FontWeight.w900,color:_ink)),const Text('Conectamos talento joven con empresas',textAlign:TextAlign.center),const SizedBox(height:28),Text(register?'Crea tu cuenta':'Bienvenido de nuevo',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:14),if(register)...[TextField(controller:fullName,decoration:const InputDecoration(labelText:'Nombre completo',border:OutlineInputBorder())),const SizedBox(height:12),if(companyAccount)...[TextField(controller:companyName,decoration:const InputDecoration(labelText:'Nombre de la empresa',border:OutlineInputBorder())),const SizedBox(height:12)]],TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Correo electrónico',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Contraseña',border:OutlineInputBorder())),const SizedBox(height:12),const Text('¿Cómo quieres ingresar?',style:TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:6),Row(children:[Expanded(child:ChoiceChip(label:const Text('Busco empleo'),selected:!companyAccount,onSelected:(_)=>setState(()=>companyAccount=false))),const SizedBox(width:12),Expanded(child:ChoiceChip(label:const Text('Soy empresa'),selected:companyAccount,onSelected:(_)=>setState(()=>companyAccount=true)))]),const SizedBox(height:18),button(register?'Crear cuenta':'Iniciar sesión',_signIn),const SizedBox(height:12),TextButton(onPressed:()=>setState(()=>register=!register),child:Text(register?'¿Ya tienes cuenta? Inicia sesión':'¿No tienes cuenta? Regístrate gratis')),const SizedBox(height:12),const Text('Demo visual · No ingreses contraseñas reales',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey,fontSize:12))]))))));
  Widget _home()=>LayoutBuilder(builder:(context,c){final wide=c.maxWidth>=850;return Scaffold(key:_homeScaffoldKey,appBar:AppBar(backgroundColor:Colors.white,title:const Text('Joblink ↗',style:TextStyle(fontWeight:FontWeight.w900,color:_blue)),actions:[if(wide)Text(premium?'Plan Premium':'Plan Gratis'),const SizedBox(width:12),IconButton(tooltip:'Cerrar sesión',onPressed:(){setState((){logged=false;section='Inicio';accountKey='';});_persist();},icon:const Icon(Icons.logout)),const SizedBox(width:12)]),drawer:wide?null:Drawer(child:companyAccount?_companyNav():_nav()),body:Row(children:[if(wide)SizedBox(width:235,child:companyAccount?_companyNav():_nav()),Expanded(child:SingleChildScrollView(padding:EdgeInsets.all(wide?30:16),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1150),child:companyAccount?_companyContent():_content())))]),bottomNavigationBar:wide||companyAccount?null:NavigationBar(selectedIndex:['Inicio','Vacantes','Postulaciones','Perfil'].contains(section)?['Inicio','Vacantes','Postulaciones','Perfil'].indexOf(section):0,onDestinationSelected:(i)=>setState(()=>section=['Inicio','Vacantes','Postulaciones','Perfil'][i]),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'Inicio'),NavigationDestination(icon:Icon(Icons.work_outline),label:'Vacantes'),NavigationDestination(icon:Icon(Icons.send_outlined),label:'Solicitudes'),NavigationDestination(icon:Icon(Icons.person_outline),label:'Perfil')])));});
  Widget _nav()=>Container(color:Colors.white,child:SafeArea(child:ListView(padding:const EdgeInsets.all(12),children:[const SizedBox(height:15),for(final item in [('Inicio',Icons.dashboard_outlined),('Vacantes',Icons.work_outline),('Postulaciones',Icons.assignment_outlined),('Guardadas',Icons.bookmark_outline),('Certificaciones',Icons.school_outlined),('Planes',Icons.workspace_premium_outlined),('Perfil',Icons.person_outline)])ListTile(leading:Icon(item.$2),title:Text(item.$1),selected:section==item.$1,selectedTileColor:const Color(0xFFEAF0FF),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),onTap:(){setState(()=>section=item.$1);if(_homeScaffoldKey.currentState?.isDrawerOpen ?? false){_homeScaffoldKey.currentState?.closeDrawer();}}),const Divider(),ListTile(title:Text('Hola, $name'),subtitle:Text(premium?'Miembro Premium':'Cuenta gratuita'),leading:const CircleAvatar(child:Icon(Icons.person)))])));
  Widget _content(){switch(section){case 'Vacantes':return _vacancies();case 'Postulaciones':return _jobCollection('Mis postulaciones',applied);case 'Guardadas':return _jobCollection('Vacantes guardadas',saved);case 'Certificaciones':return _certifications();case 'Planes':return _plans();case 'Perfil':return _profile();default:return _dashboard();}}
  Widget _heading(String title,String subtitle)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:29,fontWeight:FontWeight.w800,color:_ink)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Colors.black54)),const SizedBox(height:22)]);
  Widget _dashboard()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('¡Hola, $name! 👋',style:const TextStyle(fontSize:29,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Tu próxima gran oportunidad puede comenzar aquí. No necesitas experiencia para dar el primer paso.'),const SizedBox(height:18),button('Explorar oportunidades',()=>setState(()=>section='Vacantes'))])),const SizedBox(height:18),Wrap(spacing:12,runSpacing:12,children:[_stat('Vacantes', '${jobs.length}',Icons.work_outline),_stat('Postulaciones','${applied.length}',Icons.send_outlined),_stat('Guardadas','${saved.length}',Icons.bookmark_outline)]),const SizedBox(height:25),_heading('Oportunidades para ti','Empleos de ejemplo seleccionados para jóvenes'),...jobs.take(3).toList().asMap().entries.map((e)=>_jobCard(e.key,e.value)),const SizedBox(height:12),panel(child:Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Desarrolla nuevas habilidades',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text('Explora cursos y certificaciones de muestra')])),button('Ver cursos',()=>setState(()=>section='Certificaciones'))]))]);
  Widget _stat(String title,String value,IconData icon)=>SizedBox(width:190,child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:_blue),const SizedBox(height:12),Text(value,style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Text(title)])));
  Widget _vacancies(){final entries=jobs.asMap().entries.where((e){final j=e.value;return (j.title+' '+j.company+' '+j.city).toLowerCase().contains(search.toLowerCase())&&(filter=='Todas'||filter=='Sin experiencia'&&j.firstJob||filter=='Gratuitas'&&j.basic||filter=='Premium'&&!j.basic);}).toList();return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Explora vacantes','Encuentra oportunidades según tus intereses y habilidades'),TextField(onChanged:(s)=>setState(()=>search=s),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Puesto, empresa o ciudad',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),const SizedBox(height:14),Wrap(spacing:8,children:['Todas','Sin experiencia','Gratuitas','Premium'].map((f)=>ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f))).toList()),const SizedBox(height:15),if(entries.isEmpty)panel(child:const Text('No encontramos vacantes con esos filtros.')),...entries.map((e)=>_jobCard(e.key,e.value))]);}
  Widget _jobCard(int index,_Job job){final locked=!job.basic&&!premium;return Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(alignment:WrapAlignment.spaceBetween,spacing:12,runSpacing:8,children:[Text(job.title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19)),if(!job.basic)const Chip(label:Text('PREMIUM'))]),const SizedBox(height:6),Text('${job.company}  •  ${job.city}',style:const TextStyle(color:Colors.black54)),const SizedBox(height:8),Text('${job.salary} MXN/mes (ejemplo)  •  ${job.type}'),if(job.firstJob)const Padding(padding:EdgeInsets.only(top:8),child:Text('✓ No requiere experiencia',style:TextStyle(color:Color(0xFF15805B),fontWeight:FontWeight.w600))),const SizedBox(height:15),Wrap(spacing:8,runSpacing:8,children:[button(locked?'Desbloquear con Premium':applied.contains(index)?'Postulación registrada':'Postularme',(){if(locked){setState(()=>section='Planes');return;}setState(()=>applied.add(index));_persist();notice('Postulación de demostración registrada localmente');}),button(saved.contains(index)?'Guardada':'Guardar',(){setState(()=>saved.contains(index)?saved.remove(index):saved.add(index));_persist();},outline:true)])])));}
  Widget _jobCollection(String title,Set<int> ids)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading(title,'Actividad guardada en este navegador'),if(ids.isEmpty)panel(child:const Text('Todavía no tienes vacantes en esta sección.')),...ids.map((i)=>_jobCard(i,jobs[i]))]);
  Widget _certifications()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Aprende y certifícate','Contenido ilustrativo; no se emiten certificados reales'),for(final item in [('Excel para el trabajo','Gratis','Aprende hojas de cálculo desde cero'),('Preparación para entrevistas','Gratis','Practica cómo presentar tus habilidades'),('Marketing digital','Premium','Desarrolla habilidades para campañas'),('Análisis de datos','Premium','Fundamentos para tu primer empleo tecnológico')])Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.school_outlined,color:_blue,size:30),const SizedBox(height:8),Text(item.$1,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text(item.$3),const SizedBox(height:12),button(item.$2=='Premium'&&!premium?'Ver Premium':'Próximamente',()=>item.$2=='Premium'&&!premium?setState(()=>section='Planes'):notice('El contenido del curso aún no está conectado'))])))]);
  Widget _plans()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Elige tu plan','Precios y beneficios por definir; no hay cobros habilitados'),Wrap(spacing:14,runSpacing:14,children:[_plan('Gratis','\$0','Vacantes básicas, perfil y postulaciones',false),_plan('Plus','Próximamente','Más oportunidades, recursos de empleabilidad y cursos',true),_plan('Premium','Próximamente','Vacantes exclusivas, certificaciones y herramientas avanzadas',true)])]);
  Widget _plan(String title,String price,String desc,bool paid)=>SizedBox(width:310,child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:10),Text(price,style:const TextStyle(fontSize:24,color:_blue,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text(desc),const SizedBox(height:22),button(paid?'Solicitar información':'Plan actual',()=>notice(paid?'Los pagos y suscripciones se conectarán en una fase posterior':'Estás usando la versión gratuita'))])));
  Widget _companyNav()=>Container(color:Colors.white,child:SafeArea(child:ListView(padding:const EdgeInsets.all(12),children:[const SizedBox(height:12),for(final item in [('Inicio',Icons.dashboard_outlined),('Publicar vacante',Icons.add_circle_outline),('Mis vacantes',Icons.work_outline),('Candidatos',Icons.groups_outlined),('Mi empresa',Icons.business_outlined)])ListTile(leading:Icon(item.$2),title:Text(item.$1),selected:section==item.$1,selectedTileColor:const Color(0xFFEAF0FF),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),onTap:(){setState(()=>section=item.$1);if(_homeScaffoldKey.currentState?.isDrawerOpen ?? false){_homeScaffoldKey.currentState?.closeDrawer();}}),const Divider(),ListTile(title:Text(name),subtitle:const Text('Cuenta de empresa · Demo'),leading:const CircleAvatar(child:Icon(Icons.business))])));
  Widget _companyContent(){switch(section){case 'Publicar vacante':return _publishJob();case 'Mis vacantes':return _myCompanyJobs();case 'Candidatos':return _candidates();case 'Mi empresa':return _companyProfile();default:return _companyDashboard();}}
  Widget _companyDashboard()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('¡Bienvenida, $name!',style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('Publica oportunidades para jóvenes de 18 a 29 años, incluso sin experiencia laboral.'),const SizedBox(height:18),button('Publicar nueva vacante',()=>setState(()=>section='Publicar vacante'))])),const SizedBox(height:18),Wrap(spacing:12,runSpacing:12,children:[_stat('Vacantes publicadas','${companyJobs.length}',Icons.work_outline),_stat('Candidatos demo','${companyCandidates.length}',Icons.people_outline),_stat('Vacantes activas','${companyJobs.length}',Icons.check_circle_outline)]),const SizedBox(height:24),_heading('Mis publicaciones','Vacantes guardadas en este navegador'),...companyJobs.map((j)=>_companyJobCard(j)),if(companyJobs.isEmpty)panel(child:const Text('Aún no has publicado vacantes. Comienza creando una oportunidad de primer empleo.'))]);
  Widget _publishJob()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Publicar una vacante','Las publicaciones se guardan en el navegador actual'),panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[TextField(controller:jobTitle,decoration:const InputDecoration(labelText:'Título del puesto *',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:jobCity,decoration:const InputDecoration(labelText:'Ubicación o Remoto *',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:jobSalary,decoration:const InputDecoration(labelText:'Sueldo mensual en MXN *',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:jobType,decoration:const InputDecoration(labelText:'Modalidad (tiempo completo, medio tiempo, remoto...)',border:OutlineInputBorder())),const SizedBox(height:12),const Text('✓ Se aceptan jóvenes sin experiencia laboral',style:TextStyle(color:Color(0xFF15805B),fontWeight:FontWeight.w600)),const SizedBox(height:20),button('Publicar vacante',(){if(jobTitle.text.trim().isEmpty||jobCity.text.trim().isEmpty||jobSalary.text.trim().isEmpty){notice('Completa puesto, ubicación y sueldo');return;}setState((){final j=_Job(jobTitle.text.trim(),name,jobCity.text.trim(),jobSalary.text.trim(),jobType.text.trim().isEmpty?'Tiempo completo':jobType.text.trim());companyJobs.add(j);jobs.add(j);nextJobId++;section='Mis vacantes';jobTitle.clear();jobCity.clear();jobSalary.clear();jobType.clear();});_persist();notice('Vacante publicada en la demostración');})]))]);
  Widget _companyJobCard(_Job j)=>Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(j.title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:7),Text('${j.city} · ${j.salary} MXN/mes · ${j.type}'),const SizedBox(height:7),const Text('Sin experiencia requerida',style:TextStyle(color:Color(0xFF15805B))),const SizedBox(height:12),button('Eliminar publicación',(){final index=jobs.indexOf(j);setState((){companyJobs.remove(j);jobs.remove(j);if(index>=0){void shift(Set<int> values){final previous=values.toList();values.clear();for(final v in previous){if(v!=index)values.add(v>index?v-1:v);}}shift(applied);shift(saved);for(final key in _accounts.keys.toList()){final a=Map<String,dynamic>.from(_accounts[key] as Map);for(final field in ['applied','saved']){a[field]=(a[field] as List? ?? []).whereType<num>().map((v)=>v.toInt()).where((v)=>v!=index).map((v)=>v>index?v-1:v).toList();}_accounts[key]=a;}}});_persist();},outline:true)])));
  Widget _myCompanyJobs()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Mis vacantes','Administra tus publicaciones de ejemplo'),button('Nueva vacante',()=>setState(()=>section='Publicar vacante')),const SizedBox(height:18),...companyJobs.map(_companyJobCard),if(companyJobs.isEmpty)panel(child:const Text('No hay vacantes publicadas todavía.'))]);
  Widget _candidates()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Candidatos','Perfiles ficticios para visualizar el módulo de reclutamiento'),for(final c in [('Mariana López','Administración · Sin experiencia','Guadalajara'),('Diego Hernández','Desarrollo web · Proyectos escolares','Zapopan'),('Sofía Ramírez','Marketing · Recién egresada','Remoto'),('Luis Torres','Atención al cliente · Primer empleo','Monterrey')])Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Row(children:[CircleAvatar(child:Text(c.$1[0])),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.$1,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),Text(c.$2),Text(c.$3)])),const SizedBox(width:8),OutlinedButton(onPressed:()=>notice('Perfil de ejemplo. Los contactos reales se habilitarán con la API.'),child:const Text('Ver perfil'))]))) ]);
  Widget _companyProfile()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Mi empresa','Perfil empresarial de demostración'),panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.business,size:48,color:_blue),const SizedBox(height:10),Text(name,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(email.text),const SizedBox(height:16),const Text('Buscamos impulsar el talento joven y ofrecer oportunidades de crecimiento a personas sin experiencia.'),const SizedBox(height:15),const Text('La edición de datos fiscales, descripción, logo y contacto se conectará posteriormente.')]))]);
  Widget _profile()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Mi perfil profesional','Construye tu perfil aunque no tengas experiencia'),panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(radius:30,child:Text(name.isNotEmpty?name[0].toUpperCase():'J')),const SizedBox(height:15),Text(name,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),Text(email.text),const SizedBox(height:15),const Text('Acerca de mí'),const SizedBox(height:8),const Text('Soy una persona con ganas de aprender, desarrollar mis habilidades y encontrar mi primera oportunidad laboral.'),const Divider(height:30),const Text('Agrega tus estudios, habilidades, intereses, CV y proyectos personales en la siguiente fase.'),const SizedBox(height:15),button('Editar perfil (próximamente)',()=>notice('La edición y persistencia de perfiles aún no están conectadas'))]))]);
}
