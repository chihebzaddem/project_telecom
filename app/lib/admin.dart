import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';


class Site {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> services;
  final String? phoneNumber;
  final String? description;
  final String category;
  final Map<String, String> openingHours;

  Site({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.services,
    this.phoneNumber,
    this.description,
    required this.category,
    required this.openingHours,
  });
}

class User {
  final String id;
  final String username;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.isAdmin,
  });
}

// Providers (inchangés)
class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (username == 'admin' && password == 'admin123') {
      _user = User(id: '1', username: 'admin', isAdmin: true);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}

class SitesProvider with ChangeNotifier {
  List<Site> _sites = [];

  List<Site> get sites => _sites;

  void addSite(Site newSite) {
    _sites = [..._sites, newSite];
    notifyListeners();
  }

  void updateSite(String id, Site updatedSite) {
    _sites = _sites.map((site) => site.id == id ? updatedSite : site).toList();
    notifyListeners();
  }

  void deleteSite(String id) {
    _sites = _sites.where((site) => site.id != id).toList();
    notifyListeners();
  }
}

// Écran Admin - Version améliorée
class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final Map<String, String> _formData = {
    'name': '',
    'address': '',
    'latitude': '',
    'longitude': '',
    'services': '',
    'phoneNumber': '',
    'description': '',
  };
  bool _showAddForm = false;
  Site? _editingSite;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    if (_showAddForm) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, String username, String password) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(username, password);
    if (!success) {
      _showErrorDialog(context, 'Erreur', 'Nom d\'utilisateur ou mot de passe incorrect');
    }
  }

  void _handleLogout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
  }

  void _resetForm() {
    _formData['name'] = '';
    _formData['address'] = '';
    _formData['latitude'] = '';
    _formData['longitude'] = '';
    _formData['services'] = '';
    _formData['phoneNumber'] = '';
    _formData['description'] = '';
    setState(() {
      _showAddForm = false;
      _editingSite = null;
    });
    _animationController.reverse();
  }

  void _toggleAddForm() {
    setState(() {
      _showAddForm = !_showAddForm;
      if (_showAddForm) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _editingSite = null;
      }
    });
  }

  void _handleAddSite(BuildContext context) {
    if (_formData['name']!.isEmpty || _formData['address']!.isEmpty) {
      _showErrorDialog(context, 'Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    final newSite = Site(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _formData['name']!,
      address: _formData['address']!,
      latitude: double.tryParse(_formData['latitude']!) ?? 35.6781,
      longitude: double.tryParse(_formData['longitude']!) ?? 10.0963,
      services: _formData['services']!.split(',').map((s) => s.trim()).toList(),
      phoneNumber: _formData['phoneNumber'],
      description: _formData['description'],
      category: 'Espace TT',
      openingHours: {
        'monday': '08:00 - 17:00',
        'tuesday': '08:00 - 17:00',
        'wednesday': '08:00 - 17:00',
        'thursday': '08:00 - 17:00',
        'friday': '08:00 - 17:00',
        'saturday': '08:00 - 12:00',
        'sunday': 'Fermé',
      },
    );

    final sitesProvider = Provider.of<SitesProvider>(context, listen: false);
    sitesProvider.addSite(newSite);
    _resetForm();
    _showSuccessSnackbar(context, 'Site ajouté avec succès');
  }

  void _handleEditSite(Site site) {
    setState(() {
      _editingSite = site;
      _formData['name'] = site.name;
      _formData['address'] = site.address;
      _formData['latitude'] = site.latitude.toString();
      _formData['longitude'] = site.longitude.toString();
      _formData['services'] = site.services.join(', ');
      _formData['phoneNumber'] = site.phoneNumber ?? '';
      _formData['description'] = site.description ?? '';
      _showAddForm = true;
    });
    _animationController.forward();
  }

  void _handleUpdateSite(BuildContext context) {
    if (_editingSite == null) return;

    final updatedSite = Site(
      id: _editingSite!.id,
      name: _formData['name']!,
      address: _formData['address']!,
      latitude: double.tryParse(_formData['latitude']!) ?? _editingSite!.latitude,
      longitude: double.tryParse(_formData['longitude']!) ?? _editingSite!.longitude,
      services: _formData['services']!.split(',').map((s) => s.trim()).toList(),
      phoneNumber: _formData['phoneNumber'],
      description: _formData['description'],
      category: _editingSite!.category,
      openingHours: _editingSite!.openingHours,
    );

    final sitesProvider = Provider.of<SitesProvider>(context, listen: false);
    sitesProvider.updateSite(_editingSite!.id, updatedSite);
    _resetForm();
    _showSuccessSnackbar(context, 'Site modifié avec succès');
  }

  void _handleDeleteSite(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir supprimer "${site.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final sitesProvider = Provider.of<SitesProvider>(context, listen: false);
              sitesProvider.deleteSite(site.id);
              Navigator.of(ctx).pop();
              _showSuccessSnackbar(context, 'Site supprimé avec succès');
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Site> _filteredSites(List<Site> sites) {
    return sites.where((site) {
      return site.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          site.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
              ),
            ],
          ),
        ),
    
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF16A34A),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sitesProvider = Provider.of<SitesProvider>(context);
    final sites = sitesProvider.sites;
    final filteredSites = _filteredSites(sites);

    if (!authProvider.isAuthenticated) {
      return _buildLoginForm(context);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildAdminDashboard(context, filteredSites),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    String username = '';
    String password = '';

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E40AF),
                const Color(0xFF1E3A8A),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Espace Administrateur',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accès sécurisé au panel de gestion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => username = value,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => password = value,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _handleLogin(context, username, password),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            // Aide ou mot de passe oublié
                          },
                          child: const Text(
                            'Besoin d\'aide ?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Identifiants de démonstration',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'admin / admin123',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildAdminDashboard(BuildContext context, List<Site> filteredSites) {
    final theme = Theme.of(context);
    final sitesProvider = Provider.of<SitesProvider>(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          floating: false,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Dashboard Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E40AF),
                    const Color(0xFF1E3A8A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        'Gestion des sites TT',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E40AF).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.business, color: Color(0xFF1E40AF)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${sitesProvider.sites.length}',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: const Color(0xFF1E40AF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sites TT enregistrés',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                      onPressed: _toggleAddForm,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizeTransition(
                    sizeFactor: _animationController,
                    axisAlignment: 1.0,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _editingSite != null ? 'Modifier le site' : 'Nouveau site TT',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _resetForm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Nom de l\'espace *',
                              hint: 'Ex: Espace TT Centre-Ville',
                              value: _formData['name']!,
                              onChanged: (value) => _formData['name'] = value,
                              icon: Icons.business,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Adresse *',
                              hint: 'Adresse complète du site',
                              value: _formData['address']!,
                              onChanged: (value) => _formData['address'] = value,
                              icon: Icons.location_on,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Latitude',
                                    hint: '35.6781',
                                    value: _formData['latitude']!,
                                    onChanged: (value) => _formData['latitude'] = value,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.map,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Longitude',
                                    hint: '10.0963',
                                    value: _formData['longitude']!,
                                    onChanged: (value) => _formData['longitude'] = value,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.map,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Services (séparés par des virgules)',
                              hint: 'Internet, Mobile, Fixe',
                              value: _formData['services']!,
                              onChanged: (value) => _formData['services'] = value,
                              icon: Icons.list,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Numéro de téléphone',
                              hint: '71 230 100',
                              value: _formData['phoneNumber']!,
                              onChanged: (value) => _formData['phoneNumber'] = value,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Description',
                              hint: 'Description du site...',
                              value: _formData['description']!,
                              onChanged: (value) => _formData['description'] = value,
                              maxLines: 3,
                              icon: Icons.description,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _resetForm,
                                    child: const Text('Annuler'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (_editingSite != null) {
                                        _handleUpdateSite(context);
                                      } else {
                                        _handleAddSite(context);
                                      }
                                    },
                                    child: Text(
                                      _editingSite != null ? 'Modifier' : 'Ajouter',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un site...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        filteredSites.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun site trouvé',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Ajoutez votre premier site en cliquant sur le bouton ci-dessus'
                            : 'Aucun résultat pour "${_searchQuery}"',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final site = filteredSites[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _handleEditSite(site),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.business, size: 20, color: Color(0xFF1E40AF)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            site.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            site.address,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Modifier'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _handleEditSite(site);
                                        } else if (value == 'delete') {
                                          _handleDeleteSite(context, site);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: site.services
                                      .map((service) => Chip(
                                            label: Text(service),
                                            backgroundColor: Colors.grey[100],
                                            labelStyle: theme.textTheme.bodySmall,
                                            visualDensity: VisualDensity.compact,
                                          ))
                                      .toList(),
                                ),
                                if (site.phoneNumber != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                                      const SizedBox(width: 8),
                                      Text(
                                        site.phoneNumber!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filteredSites.length,
                ),
              ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
