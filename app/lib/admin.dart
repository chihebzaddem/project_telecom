/*import 'package:flutter/material.dart';
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
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SitesProvider>(context, listen: false).loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sitesProvider = Provider.of<SitesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Telecom Site Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            final types = ['2G', '3G', '4G'];
            sitesProvider.setNetworkType(types[index]);
          },
          tabs: const [
            Tab(text: '2G'),
            Tab(text: '3G'),
            Tab(text: '4G'),
          ],
        ),
      ),
      body: sitesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Sites',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSiteListView('2G'),
                      _buildSiteListView('3G'),
                      _buildSiteListView('4G'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            onPressed: _showImportDialog,
            mini: true,
            child: const Icon(Icons.upload_file),
            tooltip: 'Import from Excel',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddEditDialog(context, null),
            child: const Icon(Icons.add),
            tooltip: 'Add new site',
          ),
        ],
      ),
    );
  }

  Widget _buildSiteListView(String networkType) {
    return Consumer<SitesProvider>(
      builder: (context, provider, _) {
        final sites = provider.getSitesByType(networkType);
        final fieldNames = provider.getFieldNames(networkType);

        // Filter sites based on search query
        final filteredSites = sites.where((site) {
          return site[fieldNames[0]]?.toString().toLowerCase().contains(_searchQuery) ?? false;
        }).toList();

        if (filteredSites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No sites found'),
                TextButton(
                  onPressed: _showImportDialog,
                  child: const Text('Import from Excel'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredSites.length,
          itemBuilder: (context, index) {
            final site = filteredSites[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(site[fieldNames[0]]?.toString() ?? 'Unnamed Site'),
                subtitle: Text('ID: ${site[fieldNames[1]]?.toString() ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditDialog(context, index),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(context, index),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                onTap: () => _showSiteDetails(context, site, fieldNames),
              ),
            );
          },
        );
      },
    );
  }

  void _showSiteDetails(BuildContext context, Map<String, dynamic> site, List<String> fields) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(site[fields[0]]?.toString() ?? 'Site Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '$field: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: site[field]?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog() {
    final provider = Provider.of<SitesProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Sites'),
          content: const Text('Select an Excel file to import sites'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.importSitesFromExcel();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'Sites imported successfully' 
                          : 'Failed to import sites',
                    ),
                  ),
                );
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditDialog(BuildContext context, int? index) {
    final provider = Provider.of<SitesProvider>(context, listen: false);
    final isEditing = index != null;
    final networkType = provider.currentNetworkType;
    final sites = provider.getSitesByType(networkType);
    final site = isEditing ? sites[index] : {};
    final fieldNames = provider.getFieldNames(networkType);
    
    final controllers = Map.fromIterables(
      fieldNames,
      fieldNames.map((field) => 
        TextEditingController(text: site[field]?.toString() ?? '')),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Site' : 'Add New Site'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fieldNames.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: controllers[field],
                    decoration: InputDecoration(
                      labelText: field,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newSite = Map<String, String>.fromIterables(
                  fieldNames,
                  fieldNames.map((field) => controllers[field]!.text),
                );

                try {
                  if (isEditing) {
                    await provider.updateSite(networkType, index, newSite);
                  } else {
                    await provider.addSite(networkType, newSite);
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing 
                              ? 'Site updated successfully' 
                              : 'Site added successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    final provider = Provider.of<SitesProvider>(context, listen: false);
    final networkType = provider.currentNetworkType;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this site?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await provider.deleteSite(networkType, index);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Site deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class SitesProvider with ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> _sites = {
    '2G': [],
    '3G': [],
    '4G': [],
  };
  
  String _currentNetworkType = '2G';
  bool _isLoading = false;

  String get currentNetworkType => _currentNetworkType;
  bool get isLoading => _isLoading;
  
  List<Map<String, dynamic>> getSitesByType(String type) {
    return _sites[type] ?? [];
  }

  void setNetworkType(String type) {
    _currentNetworkType = type;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    if (kIsWeb) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      for (final type in _sites.keys) {
        final path = '${appDocDir.path}/${type}_sites.xlsx';
        if (await File(path).exists()) {
          await _loadExcelData(path, type);
        }
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadExcelData(String path, String networkType) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final table = excel.tables.keys.first;
      final rows = excel.tables[table]?.rows ?? [];
      
      if (rows.isNotEmpty) {
        final headers = rows[0].map((cell) => cell?.value.toString() ?? '').toList();
        final data = rows.sublist(1).map((row) {
          return Map.fromIterables(
            headers,
            row.map((cell) => cell?.value.toString() ?? ''),
          );
        }).toList();
        
        _sites[networkType] = data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading Excel data: $e');
    }
  }

  Future<bool> importSitesFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final filePath = result.files.single.path!;
        final bytes = File(filePath).readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final table = excel.tables.keys.first;
        final rows = excel.tables[table]?.rows ?? [];

        if (rows.isNotEmpty) {
          final headers = rows[0].map((cell) => cell?.value.toString() ?? '').toList();
          final importedSites = rows.sublist(1).map((row) {
            return Map.fromIterables(
              headers,
              row.map((cell) => cell?.value.toString() ?? ''),
            );
          }).toList();

          _sites[_currentNetworkType]?.addAll(importedSites);
          await _saveToExcel(_currentNetworkType);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error importing sites: $e');
      return false;
    }
  }

  Future<void> addSite(String networkType, Map<String, dynamic> site) async {
    _sites[networkType]?.add(site);
    await _saveToExcel(networkType);
    notifyListeners();
  }

  Future<void> updateSite(String networkType, int index, Map<String, dynamic> updatedSite) async {
    _sites[networkType]?[index] = updatedSite;
    await _saveToExcel(networkType);
    notifyListeners();
  }

  Future<void> deleteSite(String networkType, int index) async {
    _sites[networkType]?.removeAt(index);
    await _saveToExcel(networkType);
    notifyListeners();
  }

  Future<void> _saveToExcel(String networkType) async {
    if (kIsWeb) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final path = '${appDocDir.path}/${networkType}_sites.xlsx';
      final excel = Excel.createExcel();
      final sheet = excel['Sites'];

      final sites = _sites[networkType] ?? [];
      if (sites.isNotEmpty) {
        sheet.appendRow(sites.first.keys.toList());
        for (final site in sites) {
          sheet.appendRow(site.values.toList());
        }

        await File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.encode()!);
      }
    } catch (e) {
      debugPrint('Error saving Excel file: $e');
    }
  }

  List<String> getFieldNames(String networkType) {
    switch (networkType) {
      case '2G':
        return [
          'BscName',
          'GeranCellId',
          'cId',
          'Bsic',
          'bcchNo',
          'lac',
          'state',
          'cSysType',
          'irc',
          'xRange',
          'bcchType',
          'SiteName',
          '3GID',
          'LAT', 
          'LONG',
          'Azimuth',
          'sector',
          'dchNo'
        ];
      case '3G':
        return [
          'RNC_Name',
          '3GSiteName', 
          '3GSiteID',
          'UtranCellId',
          'Sector',
          'Sector_index',
          'cId',
          'primaryCpichPower',
          'primaryScramblingCode',
          'uarfcnDl',
          'uarfcnUl',
          'userLabel',
          'Lac', 
          'Rac',
          'LAT',
          'LONG',
          'AZIMUTH',
          'P_SiteName',
          'administrativeState',
          'operationalState',
          'Ura',
          'maximumTransmissionPower',
          'NodeId',
          'LogicalSite',
          'Region'
        ];
      case '4G':
        return [
          'NodeId_x',
          'SiteID_x',
          'eNBId',
          'EUtranCellFDDId',
          'Cell_Name',
          'cellId',
          'ECGI',
          'physicalLayerCellId',
          'freqBand',
          'earfcndl',
          'dlChannelBandwidth',
          'tac',
          'SectorCarrierId',
          'noOfTxAntennas',
          'SectorID',
          'Sector_index',
          'LAT',
          'LONG',
          'AZIMUTH',
          'Site_Name',
          'administrativeState',
          'operationalState'
        ];
      default:
        return [];
    }
  }
}

class AuthProvider with ChangeNotifier {
  String? _username;
  bool _isLoading = false;

  String? get username => _username;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _username != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (username == 'admin' && password == 'admin123') {
      _username = username;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _username = null;
    notifyListeners();
  }
}
