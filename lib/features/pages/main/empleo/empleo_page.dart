import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;

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
  bool showAuth = false;
  String publicSection = 'Inicio';
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
  String planName = 'Gratis';
  String planStart = '';
  String profileCity = '', profileEducation = '', profileSkills = '', profileBio = '', profilePhone = '', profileInterests = '';
  final Map<String, int> courseProgress = {};
  static const courses = [
    ('Excel para el trabajo', 'Gratis', 0, '4 módulos', 'Productividad', 'Hojas de cálculo, fórmulas y tablas'),
    ('Entrevistas de trabajo', 'Gratis', 0, '3 módulos', 'Empleabilidad', 'Prepara tu primera entrevista'),
    ('Comunicación profesional', 'Gratis', 0, '5 módulos', 'Habilidades blandas', 'Comunicación, trabajo en equipo y colaboración'),
    ('Marketing digital inicial', 'Plus', 199, '6 módulos', 'Marketing', 'Redes sociales y campañas digitales'),
    ('Fundamentos de análisis de datos', 'Plus', 249, '6 módulos', 'Tecnología', 'Introducción a los datos y reportes'),
    ('Diseño UX para principiantes', 'Premium', 399, '8 módulos', 'Diseño', 'Investigación y prototipos'),
    ('Introducción a programación', 'Premium', 399, '8 módulos', 'Tecnología', 'Lógica, algoritmos y proyectos'),
  ];

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
    planName = '${data['planName'] ?? (data['premium'] == true ? 'Premium' : 'Gratis')}';
    planStart = '${data['planStart'] ?? ''}';
    premium = planName != 'Gratis';
    profileCity = '${data['profileCity'] ?? ''}';
    profileEducation = '${data['profileEducation'] ?? ''}';
    profileSkills = '${data['profileSkills'] ?? ''}';
    profileBio = '${data['profileBio'] ?? ''}';
    profilePhone = '${data['profilePhone'] ?? ''}';
    profileInterests = '${data['profileInterests'] ?? ''}';
    courseProgress..clear()..addAll((data['courseProgress'] as Map? ?? {}).map((k,v)=>MapEntry('$k', (v is num ? v.toInt() : 0).clamp(0, 100))));
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
      a['planName'] = planName; a['planStart'] = planStart;
      a['profileCity'] = profileCity; a['profileEducation'] = profileEducation;
      a['profileSkills'] = profileSkills; a['profileBio'] = profileBio;
      a['profilePhone'] = profilePhone; a['profileInterests'] = profileInterests;
      a['courseProgress'] = courseProgress;
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
        'premium': false, 'planName': 'Gratis', 'applied': <int>[], 'saved': <int>[]};
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
  Widget build(BuildContext context){return Theme(data:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:_blue),scaffoldBackgroundColor:_bg),child:!_loaded?const Scaffold(body:Center(child:CircularProgressIndicator())):logged?_home():(showAuth?_login():_landing()));}
  void _openAuth({bool isCompany = false, bool isRegister = false}) {
    setState(() { companyAccount = isCompany; register = isRegister; showAuth = true; });
  }

  Widget _landing() => LayoutBuilder(builder: (context, constraints) {
    final wide = constraints.maxWidth >= 850;
    return Scaffold(
      drawer: wide ? null : Drawer(width: 310, backgroundColor: Colors.transparent, child: _mobileMenu(publicMenu: true)),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 76,
        leading: wide ? null : Builder(builder: (menuContext) => IconButton(
          tooltip: 'Abrir menú', icon: const Icon(Icons.menu_rounded, color: _ink, size: 29),
          onPressed: () => Scaffold.of(menuContext).openDrawer(),
        )),
        titleSpacing: wide ? 16 : 0,
        title: InkWell(
          onTap: () => setState(() => publicSection = 'Inicio'),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.north_east_rounded, color: _blue, size: 30),
            SizedBox(width: 8),
            Text('Joblink', style: TextStyle(color: _ink, fontSize: 27, fontWeight: FontWeight.w900)),
          ]),
        ),
        actions: [
          if (wide) ...[
            for (final item in ['Inicio', 'Vacantes', 'Para empresas', 'Planes'])
              TextButton(onPressed: () => setState(() => publicSection = item), child: Text(item)),
            const SizedBox(width: 12),
          ],
          Padding(padding: const EdgeInsets.only(right: 16, left: 6),
            child: FilledButton(onPressed: () => _openAuth(), child: const Text('Iniciar sesión'))),
        ],
      ),
      body: SingleChildScrollView(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 18, vertical: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (publicSection == 'Inicio') ...[
              Container(
                padding: EdgeInsets.all(wide ? 48 : 25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF102C72), Color(0xFF2458DC)]),
                  borderRadius: BorderRadius.circular(28)),
                child: Wrap(spacing: 35, runSpacing: 30, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  SizedBox(width: wide ? 600 : double.infinity, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('EL FUTURO PROFESIONAL EMPIEZA AQUÍ',
                        style: TextStyle(color: Color(0xFFBBD2FF), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      Text('Tu talento merece una primera oportunidad.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.13, fontSize: wide ? 48 : 35)),
                      const SizedBox(height: 18),
                      const Text('Conectamos jóvenes de 18 a 29 años con empresas que valoran su potencial, incluso sin experiencia laboral.',
                        style: TextStyle(color: Color(0xFFE5EDFF), fontSize: 17, height: 1.5)),
                      const SizedBox(height: 26),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        FilledButton.icon(onPressed: () => _openAuth(isRegister: true),
                          icon: const Icon(Icons.person_add_alt_1), label: const Text('Crear cuenta gratis'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _blue, padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 18))),
                        OutlinedButton.icon(onPressed: () => setState(() => publicSection = 'Vacantes'),
                          icon: const Icon(Icons.search), label: const Text('Explorar vacantes'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18))),
                      ]),
                    ],
                  )),
                  if (wide) Container(width: 330, padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(22)),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 58),
                      SizedBox(height: 20),
                      Text('Tu primer empleo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 23)),
                      SizedBox(height: 8),
                      Text('Vacantes • Cursos • Certificaciones • Crecimiento', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.6)),
                    ])),
                ]),
              ),
              const SizedBox(height: 38),
              _landingTitle('Todo lo que necesitas para comenzar', 'Oportunidades reales empiezan con un primer paso.'),
              _landingGrid([
                _landingFeature(Icons.work_outline, 'Vacantes para jóvenes', 'Explora oportunidades de diferentes áreas y modalidades.'),
                _landingFeature(Icons.school_outlined, 'Aprende y certifícate', 'Desarrolla habilidades con cursos y certificaciones de demostración.'),
                _landingFeature(Icons.person_outline, 'Perfil profesional', 'Presenta tus habilidades, estudios e intereses.'),
                _landingFeature(Icons.business_outlined, 'Empresas y talento', 'Publica vacantes y encuentra candidatos con potencial.'),
              ]),
              const SizedBox(height: 38),
              _landingTitle('Oportunidades destacadas', 'Vacantes de ejemplo, sin experiencia previa.'),
              _landingGrid(jobs.take(4).map((j) => _landingJob(j)).toList()),
              const SizedBox(height: 38),
              _landingCallToAction(),
            ] else if (publicSection == 'Vacantes') ...[
              _landingTitle('Explora vacantes', 'Una vista previa de oportunidades para comenzar tu carrera.'),
              _landingGrid(jobs.map((j) => _landingJob(j)).toList()),
            ] else if (publicSection == 'Para empresas') ...[
              _landingTitle('Encuentra talento joven', 'Publica oportunidades y conecta con jóvenes de 18 a 29 años.'),
              _landingGrid([
                _landingFeature(Icons.add_circle_outline, 'Publica vacantes', 'Crea ofertas laborales desde tu panel empresarial.'),
                _landingFeature(Icons.groups_outlined, 'Revisa candidatos', 'Organiza tus postulaciones y candidatos.'),
                _landingFeature(Icons.handshake_outlined, 'Impulsa el primer empleo', 'Abre las puertas al talento sin experiencia.'),
                _landingFeature(Icons.dashboard_outlined, 'Administra tu empresa', 'Gestiona tus publicaciones desde un solo lugar.'),
              ]),
              const SizedBox(height: 30),
              Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: () => _openAuth(isCompany: true, isRegister: true),
                icon: const Icon(Icons.business), label: const Text('Registrar mi empresa'))),
            ] else ...[
              _landingTitle('Planes para crecer', 'Elige la experiencia que mejor se adapte a tus objetivos.'),
              _landingGrid([
                _landingPlan('Gratis', '\$0', 'Vacantes básicas y cursos gratuitos'),
                _landingPlan('Plus', '\$99', 'Más oportunidades y cursos'),
                _landingPlan('Premium', '\$199', 'Acceso completo a beneficios demo'),
              ]),
              const SizedBox(height: 15),
              const Text('Precios mensuales de demostración en MXN. No se realizan cobros reales.', style: TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 42),
            _corporateFooter(),
          ]),
        ),
      ))),
    );
  });

  // Redes sociales oficiales de Joblink.
  static const Map<String, String> _socialUrls = {
    'Facebook': 'https://www.facebook.com/profile.php?id=61596343604467',
    'Instagram': 'https://www.instagram.com/joblink.com.mx/',
    'TikTok': 'https://www.tiktok.com/@joblink.com.mx',
  };

  Widget _footerLink(String label, String target) => TextButton(
    onPressed: () => setState(() => publicSection = target),
    style: TextButton.styleFrom(foregroundColor: const Color(0xFFCBD6F2), padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft),
    child: Text(label),
  );

  Widget _socialButton(String name, IconData icon) {
    final url = _socialUrls[name];
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: 'Abrir $name de Joblink',
      child: Semantics(
        label: 'Visitar $name de Joblink',
        link: true,
        child: InkWell(
          onTap: () => html.window.open(url, '_blank'),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _corporateFooter() => LayoutBuilder(builder: (context, c) {
    final narrow = c.maxWidth < 700;
    Widget brand = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.north_east_rounded, color: Color(0xFF8EB5FF), size: 32),
        SizedBox(width: 9),
        Text('Joblink', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 15),
      const Text('Tu talento merece una oportunidad.',
        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      const Text('Conectamos a jóvenes de 18 a 29 años con empresas que creen en su potencial, incluso sin experiencia laboral.',
        style: TextStyle(color: Color(0xFFCAD5EA), height: 1.6)),
    ]);
    Widget explore = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Explora Joblink', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 13),
      _footerLink('Inicio', 'Inicio'),
      _footerLink('Buscar vacantes', 'Vacantes'),
      _footerLink('Planes y beneficios', 'Planes'),
    ]);
    Widget companies = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Para empresas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 13),
      _footerLink('Contratar talento joven', 'Para empresas'),
      _footerLink('Publicar oportunidades', 'Para empresas'),
      TextButton(onPressed: () => _openAuth(isCompany: true, isRegister: true),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFCBD6F2), padding: EdgeInsets.zero),
        child: const Text('Registrar empresa')),
    ]);
    Widget social = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Síguenos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 13),
      const Text('Conoce nuestras redes sociales', style: TextStyle(color: Color(0xFFCBD6F2))),
      const SizedBox(height: 15),
      Wrap(spacing: 9, runSpacing: 9, children: [
        _socialButton('Facebook', Icons.facebook),
        _socialButton('Instagram', Icons.camera_alt_outlined),
        _socialButton('TikTok', Icons.music_note_rounded),
      ]),
      const SizedBox(height: 10),
      const Text('Visita nuestras cuentas oficiales',
        style: TextStyle(color: Color(0xFF9FB0CE), fontSize: 11)),
    ]);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 22 : 36, vertical: 36),
      decoration: BoxDecoration(color: const Color(0xFF101D3C), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 32, runSpacing: 30, children: [
          SizedBox(width: narrow ? c.maxWidth - 44 : 290, child: brand),
          SizedBox(width: narrow ? 150 : 165, child: explore),
          SizedBox(width: narrow ? 150 : 175, child: companies),
          SizedBox(width: narrow ? c.maxWidth - 44 : 220, child: social),
        ]),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFF34425E)),
        const SizedBox(height: 12),
        const Wrap(alignment: WrapAlignment.spaceBetween, spacing: 18, runSpacing: 8, children: [
          Text('© 2026 Joblink. Todos los derechos reservados.',
            style: TextStyle(color: Color(0xFFB7C6E0), fontSize: 12)),
          Text('Plataforma demostrativa · Sin pagos reales',
            style: TextStyle(color: Color(0xFFB7C6E0), fontSize: 12)),
        ]),
      ]),
    );
  });

  Widget _landingTitle(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 15)),
    ]));

  Widget _landingGrid(List<Widget> items) => LayoutBuilder(builder: (context, c) {
    final count = c.maxWidth >= 1050 ? 4 : c.maxWidth >= 650 ? 2 : 1;
    final itemWidth = (c.maxWidth - (count - 1) * 16) / count;
    return Wrap(spacing: 16, runSpacing: 16, children: items.map((item) => SizedBox(width: itemWidth, child: item)).toList());
  });

  Widget _landingFeature(IconData icon, String title, String subtitle) => SizedBox(height: 210, child: panel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _blue, size: 36), const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.4)),
    ])));

  Widget _landingJob(_Job job) => SizedBox(height: 245, child: panel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 8), Text(job.company, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 8), Text(job.city, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 10), Text('${job.salary} MXN/mes', style: const TextStyle(fontWeight: FontWeight.w600)),
      const Spacer(),
      TextButton.icon(onPressed: () => _openAuth(), icon: const Icon(Icons.arrow_forward), label: const Text('Ver y postularme')),
    ])));

  Widget _landingPlan(String title, String price, String description) => SizedBox(height: 220, child: panel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      const SizedBox(height: 12), Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: _blue)),
      const Text('MXN / mes', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 12), Text(description), const Spacer(),
      TextButton(onPressed: () => _openAuth(isRegister: true), child: const Text('Elegir plan')),
    ])));

  Widget _landingCallToAction() => Container(padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(22)),
    child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20, runSpacing: 15, children: [
        const SizedBox(width: 580, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Listo para dar el siguiente paso?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 25, color: _ink)),
          SizedBox(height: 7), Text('Únete a Joblink y comienza a construir tu futuro profesional.'),
        ])),
        FilledButton(onPressed: () => _openAuth(isRegister: true), child: const Text('Comenzar gratis')),
      ]));

  // Menú lateral móvil de Joblink, independiente de cualquier módulo anterior.
  Widget _mobileMenu({required bool publicMenu}) {
    final entries = publicMenu
        ? <(String, IconData)>[
            ('Inicio', Icons.home_outlined),
            ('Vacantes', Icons.work_outline_rounded),
            ('Para empresas', Icons.business_outlined),
            ('Planes', Icons.workspace_premium_outlined),
          ]
        : companyAccount
            ? <(String, IconData)>[
                ('Inicio', Icons.dashboard_outlined),
                ('Publicar vacante', Icons.add_circle_outline),
                ('Mis vacantes', Icons.work_outline),
                ('Candidatos', Icons.groups_outlined),
                ('Mi empresa', Icons.business_outlined),
              ]
            : <(String, IconData)>[
                ('Inicio', Icons.dashboard_outlined),
                ('Vacantes', Icons.work_outline),
                ('Postulaciones', Icons.assignment_outlined),
                ('Guardadas', Icons.bookmark_outline),
                ('Certificaciones', Icons.school_outlined),
                ('Planes', Icons.workspace_premium_outlined),
                ('Perfil', Icons.person_outline),
              ];
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topRight: Radius.circular(26), bottomRight: Radius.circular(26)),
        ),
        child: Column(children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Container(
                width: 49, height: 49,
                decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.north_east_rounded, color: _blue, size: 31),
              ),
              const SizedBox(width: 11),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Joblink', style: TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.w900)),
                Text('Tu futuro comienza aquí', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ])),
              IconButton(tooltip: 'Cerrar menú', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          const SizedBox(height: 22),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
            Padding(padding: const EdgeInsets.only(left: 14, bottom: 12), child: Text(
              publicMenu ? 'EXPLORA JOBLINK' : companyAccount ? 'PANEL EMPRESARIAL' : 'MI ESPACIO',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.black45),
            )),
            for (final item in entries) Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                leading: Icon(item.$2, color: (publicMenu ? publicSection : section) == item.$1 ? _blue : const Color(0xFF53617A)),
                title: Text(item.$1, style: TextStyle(fontWeight: FontWeight.w700,
                  color: (publicMenu ? publicSection : section) == item.$1 ? _blue : _ink)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black38),
                selected: (publicMenu ? publicSection : section) == item.$1,
                selectedTileColor: const Color(0xFFEAF0FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() { if (publicMenu) { publicSection = item.$1; } else { section = item.$1; } });
                },
              ),
            ),
          ])),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity,
            child: publicMenu
              ? FilledButton.icon(
                  onPressed: () { Navigator.of(context).pop(); _openAuth(); },
                  icon: const Icon(Icons.login_rounded), label: const Text('Iniciar sesión'),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() { logged = false; showAuth = false; publicSection = 'Inicio'; section = 'Inicio'; accountKey = ''; });
                    _persist();
                  },
                  icon: const Icon(Icons.logout_rounded), label: const Text('Cerrar sesión'),
                ),
          )),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _login()=>Scaffold(appBar:AppBar(backgroundColor:Colors.white,leading:IconButton(tooltip:'Volver al inicio',icon:const Icon(Icons.arrow_back),onPressed:()=>setState(()=>showAuth=false)),title:const Text('Joblink',style:TextStyle(color:_blue,fontWeight:FontWeight.w900))),body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:panel(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Icon(Icons.trending_up_rounded,size:54,color:_blue),const SizedBox(height:12),const Text('Joblink',textAlign:TextAlign.center,style:TextStyle(fontSize:31,fontWeight:FontWeight.w900,color:_ink)),const Text('Conectamos talento joven con empresas',textAlign:TextAlign.center),const SizedBox(height:28),Text(register?'Crea tu cuenta':'Bienvenido de nuevo',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:14),if(register)...[TextField(controller:fullName,decoration:const InputDecoration(labelText:'Nombre completo',border:OutlineInputBorder())),const SizedBox(height:12),if(companyAccount)...[TextField(controller:companyName,decoration:const InputDecoration(labelText:'Nombre de la empresa',border:OutlineInputBorder())),const SizedBox(height:12)]],TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Correo electrónico',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Contraseña',border:OutlineInputBorder())),const SizedBox(height:12),const Text('¿Cómo quieres ingresar?',style:TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:6),Row(children:[Expanded(child:ChoiceChip(label:const Text('Busco empleo'),selected:!companyAccount,onSelected:(_)=>setState(()=>companyAccount=false))),const SizedBox(width:12),Expanded(child:ChoiceChip(label:const Text('Soy empresa'),selected:companyAccount,onSelected:(_)=>setState(()=>companyAccount=true)))]),const SizedBox(height:18),button(register?'Crear cuenta':'Iniciar sesión',_signIn),const SizedBox(height:12),TextButton(onPressed:()=>setState(()=>register=!register),child:Text(register?'¿Ya tienes cuenta? Inicia sesión':'¿No tienes cuenta? Regístrate gratis')),const SizedBox(height:12),const Text('Demo visual · No ingreses contraseñas reales',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey,fontSize:12))]))))));
  Widget _home()=>LayoutBuilder(builder:(context,c){final wide=c.maxWidth>=850;return Scaffold(key:_homeScaffoldKey,appBar:AppBar(backgroundColor:Colors.white,title:const Text('Joblink ↗',style:TextStyle(fontWeight:FontWeight.w900,color:_blue)),actions:[if(wide)Text('Plan $planName'),const SizedBox(width:12),IconButton(tooltip:'Cerrar sesión',onPressed:(){setState((){logged=false;showAuth=false;publicSection='Inicio';section='Inicio';accountKey='';});_persist();},icon:const Icon(Icons.logout)),const SizedBox(width:12)]),drawer:wide?null:Drawer(width:310,backgroundColor:Colors.transparent,child:_mobileMenu(publicMenu:false)),body:Row(children:[if(wide)SizedBox(width:235,child:companyAccount?_companyNav():_nav()),Expanded(child:SingleChildScrollView(padding:EdgeInsets.all(wide?30:16),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1150),child:companyAccount?_companyContent():_content())))]),bottomNavigationBar:wide||companyAccount?null:NavigationBar(selectedIndex:['Inicio','Vacantes','Postulaciones','Perfil'].contains(section)?['Inicio','Vacantes','Postulaciones','Perfil'].indexOf(section):0,onDestinationSelected:(i)=>setState(()=>section=['Inicio','Vacantes','Postulaciones','Perfil'][i]),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'Inicio'),NavigationDestination(icon:Icon(Icons.work_outline),label:'Vacantes'),NavigationDestination(icon:Icon(Icons.send_outlined),label:'Solicitudes'),NavigationDestination(icon:Icon(Icons.person_outline),label:'Perfil')]));});
  Widget _nav()=>Container(color:Colors.white,child:SafeArea(child:ListView(padding:const EdgeInsets.all(12),children:[const SizedBox(height:15),for(final item in [('Inicio',Icons.dashboard_outlined),('Vacantes',Icons.work_outline),('Postulaciones',Icons.assignment_outlined),('Guardadas',Icons.bookmark_outline),('Certificaciones',Icons.school_outlined),('Planes',Icons.workspace_premium_outlined),('Perfil',Icons.person_outline)])ListTile(leading:Icon(item.$2),title:Text(item.$1),selected:section==item.$1,selectedTileColor:const Color(0xFFEAF0FF),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),onTap:(){setState(()=>section=item.$1);if(_homeScaffoldKey.currentState?.isDrawerOpen ?? false){_homeScaffoldKey.currentState?.closeDrawer();}}),const Divider(),ListTile(title:Text('Hola, $name'),subtitle:Text('Plan $planName'),leading:const CircleAvatar(child:Icon(Icons.person)))])));
  Widget _content(){switch(section){case 'Vacantes':return _vacancies();case 'Postulaciones':return _jobCollection('Mis postulaciones',applied);case 'Guardadas':return _jobCollection('Vacantes guardadas',saved);case 'Certificaciones':return _certifications();case 'Planes':return _plans();case 'Perfil':return _profile();default:return _dashboard();}}
  Widget _heading(String title,String subtitle)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:29,fontWeight:FontWeight.w800,color:_ink)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Colors.black54)),const SizedBox(height:22)]);
  Widget _dashboard()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('¡Hola, $name! 👋',style:const TextStyle(fontSize:29,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Tu próxima gran oportunidad puede comenzar aquí. No necesitas experiencia para dar el primer paso.'),const SizedBox(height:18),button('Explorar oportunidades',()=>setState(()=>section='Vacantes'))])),const SizedBox(height:18),Wrap(spacing:12,runSpacing:12,children:[_stat('Vacantes', '${jobs.length}',Icons.work_outline),_stat('Postulaciones','${applied.length}',Icons.send_outlined),_stat('Guardadas','${saved.length}',Icons.bookmark_outline)]),const SizedBox(height:25),_heading('Oportunidades para ti','Empleos de ejemplo seleccionados para jóvenes'),_responsiveCards(jobs.take(4).toList().asMap().entries.map((e)=>_jobCard(e.key,e.value)).toList()),const SizedBox(height:12),panel(child:Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Desarrolla nuevas habilidades',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text('Explora cursos y certificaciones de muestra')])),button('Ver cursos',()=>setState(()=>section='Certificaciones'))]))]);
  Widget _stat(String title,String value,IconData icon)=>SizedBox(width:190,child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:_blue),const SizedBox(height:12),Text(value,style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Text(title)])));
  Widget _vacancies(){final entries=jobs.asMap().entries.where((e){final j=e.value;return (j.title+' '+j.company+' '+j.city).toLowerCase().contains(search.toLowerCase())&&(filter=='Todas'||filter=='Sin experiencia'&&j.firstJob||filter=='Gratuitas'&&j.basic||filter=='Premium'&&!j.basic);}).toList();return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Explora vacantes','Encuentra oportunidades según tus intereses y habilidades'),TextField(onChanged:(s)=>setState(()=>search=s),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Puesto, empresa o ciudad',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),const SizedBox(height:14),Wrap(spacing:8,children:['Todas','Sin experiencia','Gratuitas','Premium'].map((f)=>ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f))).toList()),const SizedBox(height:15),if(entries.isEmpty)panel(child:const Text('No encontramos vacantes con esos filtros.')),_responsiveCards(entries.map((e)=>_jobCard(e.key,e.value)).toList())]);}
  Widget _jobCard(int index,_Job job){final locked=!job.basic&&!premium;return Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(alignment:WrapAlignment.spaceBetween,spacing:12,runSpacing:8,children:[Text(job.title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19)),if(!job.basic)const Chip(label:Text('PREMIUM'))]),const SizedBox(height:6),Text('${job.company}  •  ${job.city}',style:const TextStyle(color:Colors.black54)),const SizedBox(height:8),Text('${job.salary} MXN/mes (ejemplo)  •  ${job.type}'),if(job.firstJob)const Padding(padding:EdgeInsets.only(top:8),child:Text('✓ No requiere experiencia',style:TextStyle(color:Color(0xFF15805B),fontWeight:FontWeight.w600))),const SizedBox(height:15),Wrap(spacing:8,runSpacing:8,children:[button(locked?'Desbloquear con Premium':applied.contains(index)?'Postulación registrada':'Postularme',(){if(locked){setState(()=>section='Planes');return;}setState(()=>applied.add(index));_persist();notice('Postulación de demostración registrada localmente');}),button(saved.contains(index)?'Guardada':'Guardar',(){setState(()=>saved.contains(index)?saved.remove(index):saved.add(index));_persist();},outline:true)])])));}
  Widget _jobCollection(String title,Set<int> ids)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading(title,'Actividad guardada en este navegador'),if(ids.isEmpty)panel(child:const Text('Todavía no tienes vacantes en esta sección.')),_responsiveCards(ids.where((i)=>i>=0&&i<jobs.length).map((i)=>_jobCard(i,jobs[i])).toList())]);
  bool _courseUnlocked(String tier) => tier == 'Gratis' || planName == 'Premium' || (tier == 'Plus' && planName == 'Plus');

  Widget _responsiveCards(List<Widget> children, {double minWidth = 300}) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(spacing: 14, runSpacing: 14, children: children.map((w) => SizedBox(width: width, child: w)).toList());
    },
  );

  Widget _certifications() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Certificaciones y cursos', 'Catálogo demostrativo · El progreso se guarda en este navegador'),
      const SizedBox(height: 16),
      _responsiveCards(courses.map((course) {
        final title = course.$1, tier = course.$2;
        final progress = courseProgress[title] ?? 0;
        final unlocked = _courseUnlocked(tier);
        return panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.school_outlined, color: _blue, size: 30), const Spacer(), Chip(label: Text(tier))]),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 6), Text(course.$6),
          const SizedBox(height: 8), Text('${course.$5} · ${course.$4}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8), Text(course.$3 == 0 ? 'Incluido sin costo' : 'Valor referencial: \$${course.$3} MXN', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12), LinearProgressIndicator(value: progress / 100, minHeight: 7, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 6), Text(progress == 100 ? 'Curso completado (demo)' : 'Progreso: $progress%'),
          const SizedBox(height: 14),
          button(!unlocked ? 'Desbloquear con $tier' : progress == 100 ? 'Ver constancia demo' : progress == 0 ? 'Iniciar curso' : 'Continuar curso', () {
            if (!unlocked) { setState(() => section = 'Planes'); return; }
            if (progress == 100) { _showCertificate(title); return; }
            _showCourse(title, course.$4);
          }),
        ]));
      }).toList()),
    ]);
  }

  void _showCourse(String title, String modules) {
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$modules · Simulación de aprendizaje'),
        const SizedBox(height: 12),
        const Text('En esta demostración puedes registrar avances de 25% hasta completar el curso. El contenido educativo real se integrará después.'),
        const SizedBox(height: 12),
        Text('Progreso actual: ${courseProgress[title] ?? 0}%'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        FilledButton(onPressed: () {
          setState(() => courseProgress[title] = ((courseProgress[title] ?? 0) + 25).clamp(0, 100));
          _persist();
          Navigator.pop(dialogContext);
          notice(courseProgress[title] == 100 ? 'Curso completado en modo demostración' : 'Avance guardado localmente');
        }, child: const Text('Registrar avance +25%')),
      ],
    ));
  }

  void _showCertificate(String title) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Constancia de demostración'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.workspace_premium, size: 70, color: _blue),
        const SizedBox(height: 12), Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
        const SizedBox(height: 8), Text('Completó el curso: $title', textAlign: TextAlign.center),
        const SizedBox(height: 12), const Text('Documento ilustrativo. No es una certificación oficial.', textAlign: TextAlign.center),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ));
  }

  Widget _plans() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Planes Joblink', 'Precios propuestos en MXN/mes · Suscripciones simuladas, sin cargos reales'),
      const SizedBox(height: 16),
      _responsiveCards([
        _plan('Gratis', 0, ['Vacantes básicas', 'Perfil profesional', 'Postulaciones gratuitas', 'Cursos de nivel Gratis']),
        _plan('Plus', 99, ['Todo lo de Gratis', 'Vacantes Plus', 'Cursos Gratis y Plus', 'Seguimiento de postulaciones']),
        _plan('Premium', 199, ['Todo lo de Plus', 'Vacantes Premium', 'Todos los cursos demo', 'Constancias de demostración']),
      ]),
      const SizedBox(height: 20),
      panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mi suscripción: $planName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 6),
        Text(planName == 'Gratis' ? 'Sin suscripción de pago' : 'Activación demo: $planStart · Sin cobro ni renovación automática'),
        if (planName != 'Gratis') ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => _confirmPlan('Gratis'), icon: const Icon(Icons.cancel_outlined), label: const Text('Cancelar suscripción demo')),
        ],
      ])),
    ]);
  }

  Widget _plan(String title, int price, List<String> benefits) {
    final selected = planName == title;
    return panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const Spacer(), if (selected) const Chip(label: Text('Actual'))]),
      const SizedBox(height: 14),
      Text(price == 0 ? 'Gratis' : '\$$price MXN / mes', style: const TextStyle(fontSize: 25, color: _blue, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      ...benefits.map((benefit) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF15805B), size: 19), const SizedBox(width: 8), Expanded(child: Text(benefit)),
      ]))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: selected ? null : () => _confirmPlan(title), child: Text(selected ? 'Plan activo' : title == 'Gratis' ? 'Cambiar a Gratis' : 'Elegir $title'))),
    ]));
  }

  void _confirmPlan(String chosen) {
    final cost = chosen == 'Plus' ? 99 : chosen == 'Premium' ? 199 : 0;
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(chosen == 'Gratis' ? 'Cancelar plan de demostración' : 'Confirmar plan $chosen'),
      content: Text(chosen == 'Gratis'
          ? 'Regresarás al plan Gratis y perderás acceso a los beneficios Plus/Premium. Se conservará tu progreso local.'
          : 'Precio ilustrativo: \$$cost MXN/mes. Esta activación es una simulación local: NO se solicitará tarjeta, NO se cobrará y NO habrá renovación automática.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
        FilledButton(onPressed: () {
          setState(() {
            planName = chosen;
            premium = chosen != 'Gratis';
            planStart = chosen == 'Gratis' ? '' : DateTime.now().toLocal().toIso8601String().substring(0, 10);
          });
          _persist();
          Navigator.pop(ctx);
          notice('Plan $chosen activado localmente (sin cobro)');
        }, child: const Text('Confirmar demo')),
      ],
    ));
  }

  Widget _companyNav()=>Container(color:Colors.white,child:SafeArea(child:ListView(padding:const EdgeInsets.all(12),children:[const SizedBox(height:12),for(final item in [('Inicio',Icons.dashboard_outlined),('Publicar vacante',Icons.add_circle_outline),('Mis vacantes',Icons.work_outline),('Candidatos',Icons.groups_outlined),('Mi empresa',Icons.business_outlined)])ListTile(leading:Icon(item.$2),title:Text(item.$1),selected:section==item.$1,selectedTileColor:const Color(0xFFEAF0FF),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),onTap:(){setState(()=>section=item.$1);if(_homeScaffoldKey.currentState?.isDrawerOpen ?? false){_homeScaffoldKey.currentState?.closeDrawer();}}),const Divider(),ListTile(title:Text(name),subtitle:const Text('Cuenta de empresa · Demo'),leading:const CircleAvatar(child:Icon(Icons.business)))])));
  Widget _companyContent(){switch(section){case 'Publicar vacante':return _publishJob();case 'Mis vacantes':return _myCompanyJobs();case 'Candidatos':return _candidates();case 'Mi empresa':return _companyProfile();default:return _companyDashboard();}}
  Widget _companyDashboard()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('¡Bienvenida, $name!',style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('Publica oportunidades para jóvenes de 18 a 29 años, incluso sin experiencia laboral.'),const SizedBox(height:18),button('Publicar nueva vacante',()=>setState(()=>section='Publicar vacante'))])),const SizedBox(height:18),Wrap(spacing:12,runSpacing:12,children:[_stat('Vacantes publicadas','${companyJobs.length}',Icons.work_outline),_stat('Candidatos demo','${companyCandidates.length}',Icons.people_outline),_stat('Vacantes activas','${companyJobs.length}',Icons.check_circle_outline)]),const SizedBox(height:24),_heading('Mis publicaciones','Vacantes guardadas en este navegador'),_responsiveCards(companyJobs.map((j)=>_companyJobCard(j)).toList()),if(companyJobs.isEmpty)panel(child:const Text('Aún no has publicado vacantes. Comienza creando una oportunidad de primer empleo.'))]);
  Widget _publishJob()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Publicar una vacante','Las publicaciones se guardan en el navegador actual'),panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[TextField(controller:jobTitle,decoration:const InputDecoration(labelText:'Título del puesto *',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:jobCity,decoration:const InputDecoration(labelText:'Ubicación o Remoto *',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:jobSalary,decoration:const InputDecoration(labelText:'Sueldo mensual en MXN *',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:jobType,decoration:const InputDecoration(labelText:'Modalidad (tiempo completo, medio tiempo, remoto...)',border:OutlineInputBorder())),const SizedBox(height:12),const Text('✓ Se aceptan jóvenes sin experiencia laboral',style:TextStyle(color:Color(0xFF15805B),fontWeight:FontWeight.w600)),const SizedBox(height:20),button('Publicar vacante',(){if(jobTitle.text.trim().isEmpty||jobCity.text.trim().isEmpty||jobSalary.text.trim().isEmpty){notice('Completa puesto, ubicación y sueldo');return;}setState((){final j=_Job(jobTitle.text.trim(),name,jobCity.text.trim(),jobSalary.text.trim(),jobType.text.trim().isEmpty?'Tiempo completo':jobType.text.trim());companyJobs.add(j);jobs.add(j);nextJobId++;section='Mis vacantes';jobTitle.clear();jobCity.clear();jobSalary.clear();jobType.clear();});_persist();notice('Vacante publicada en la demostración');})]))]);
  Widget _companyJobCard(_Job j)=>Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(j.title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:7),Text('${j.city} · ${j.salary} MXN/mes · ${j.type}'),const SizedBox(height:7),const Text('Sin experiencia requerida',style:TextStyle(color:Color(0xFF15805B))),const SizedBox(height:12),button('Eliminar publicación',(){final index=jobs.indexOf(j);setState((){companyJobs.remove(j);jobs.remove(j);if(index>=0){void shift(Set<int> values){final previous=values.toList();values.clear();for(final v in previous){if(v!=index)values.add(v>index?v-1:v);}}shift(applied);shift(saved);for(final key in _accounts.keys.toList()){final a=Map<String,dynamic>.from(_accounts[key] as Map);for(final field in ['applied','saved']){a[field]=(a[field] as List? ?? []).whereType<num>().map((v)=>v.toInt()).where((v)=>v!=index).map((v)=>v>index?v-1:v).toList();}_accounts[key]=a;}}});_persist();},outline:true)])));
  Widget _myCompanyJobs()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Mis vacantes','Administra tus publicaciones de ejemplo'),button('Nueva vacante',()=>setState(()=>section='Publicar vacante')),const SizedBox(height:18),_responsiveCards(companyJobs.map(_companyJobCard).toList()),if(companyJobs.isEmpty)panel(child:const Text('No hay vacantes publicadas todavía.'))]);
  Widget _candidates()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Candidatos','Perfiles ficticios para visualizar el módulo de reclutamiento'),for(final c in [('Mariana López','Administración · Sin experiencia','Guadalajara'),('Diego Hernández','Desarrollo web · Proyectos escolares','Zapopan'),('Sofía Ramírez','Marketing · Recién egresada','Remoto'),('Luis Torres','Atención al cliente · Primer empleo','Monterrey')])Padding(padding:const EdgeInsets.only(bottom:12),child:panel(child:Row(children:[CircleAvatar(child:Text(c.$1[0])),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.$1,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),Text(c.$2),Text(c.$3)])),const SizedBox(width:8),OutlinedButton(onPressed:()=>notice('Perfil de ejemplo. Los contactos reales se habilitarán con la API.'),child:const Text('Ver perfil'))]))) ]);
  Widget _companyProfile()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_heading('Mi empresa','Perfil empresarial de demostración'),panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.business,size:48,color:_blue),const SizedBox(height:10),Text(name,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(email.text),const SizedBox(height:16),const Text('Buscamos impulsar el talento joven y ofrecer oportunidades de crecimiento a personas sin experiencia.'),const SizedBox(height:15),const Text('La edición de datos fiscales, descripción, logo y contacto se conectará posteriormente.')]))]);
  Widget _profile() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('Mi perfil profesional', 'Tu información se conserva localmente en este navegador'),
    const SizedBox(height: 16),
    panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(radius: 30, child: Text(name.isEmpty ? 'J' : name[0].toUpperCase())), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)), Text(email.text)]))]),
      const SizedBox(height: 20),
      _profileLine('Ubicación', profileCity),
      _profileLine('Teléfono', profilePhone),
      _profileLine('Estudios', profileEducation),
      _profileLine('Habilidades', profileSkills),
      _profileLine('Intereses', profileInterests),
      _profileLine('Acerca de mí', profileBio),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        Chip(label: Text('Plan $planName')),
        Chip(label: Text('${applied.length} postulaciones')),
        Chip(label: Text('${courseProgress.values.where((p) => p == 100).length} cursos completados')),
      ]),
      const SizedBox(height: 18),
      button('Editar mi perfil', _editProfile),
    ])),
  ]);

  Widget _profileLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
      Expanded(child: Text(value.trim().isEmpty ? 'Sin registrar' : value)),
    ]),
  );

  void _editProfile() {
    final controllers = [name, profileCity, profilePhone, profileEducation, profileSkills, profileInterests, profileBio]
        .map((value) => TextEditingController(text: value)).toList();
    final labels = ['Nombre completo', 'Ciudad', 'Teléfono', 'Estudios', 'Habilidades (separadas por comas)', 'Intereses profesionales', 'Acerca de mí'];
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Editar perfil'),
      content: SizedBox(width: 540, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < controllers.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
          controller: controllers[i], maxLines: i == 6 ? 3 : 1,
          decoration: InputDecoration(labelText: labels[i], border: const OutlineInputBorder()),
        )),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () {
          if (controllers[0].text.trim().isEmpty) { notice('Ingresa tu nombre'); return; }
          setState(() {
            name = controllers[0].text.trim(); profileCity = controllers[1].text.trim();
            profilePhone = controllers[2].text.trim(); profileEducation = controllers[3].text.trim();
            profileSkills = controllers[4].text.trim(); profileInterests = controllers[5].text.trim();
            profileBio = controllers[6].text.trim();
          });
          _persist(); Navigator.pop(ctx); notice('Perfil guardado en este navegador');
        }, child: const Text('Guardar cambios')),
      ],
    )).then((_) { for (final c in controllers) { c.dispose(); } });
  }
}
