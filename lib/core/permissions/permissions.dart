/// Permission enum defining all app permissions
enum Permission {
  // ==================== ADMIN PERMISSIONS ====================
  /// Manage users (add, edit, delete mechanics, customers, admins)
  manageUsers,

  /// Access and modify system settings
  manageSettings,

  /// View reports and analytics
  viewReports,

  /// Delete any data (customers, vehicles, job cards, etc.)
  deleteData,

  /// Manage inventory (add, edit, delete spare parts)
  manageInventory,

  /// Create job cards for any customer
  createJobCards,

  /// Delete job cards
  deleteJobCards,

  /// View all customers
  viewAllCustomers,

  /// Add new customers
  addCustomer,

  /// Edit any customer data
  editCustomers,

  /// View all mechanics
  viewAllMechanics,

  /// Edit mechanic data
  editMechanics,

  // ==================== SUPER ADMIN PERMISSIONS ====================
  /// Create new admin accounts (super admin only)
  createAdmins,

  // ==================== MECHANIC PERMISSIONS ====================
  /// View job cards (only assigned ones for mechanics)
  viewJobCards,

  /// Update job card status and details
  updateJobCards,

  /// Add parts to vehicles/job cards
  addPartsToVehicles,

  /// View customer details (read-only)
  viewCustomerDetails,

  /// View inventory (read-only)
  viewInventory,

  /// View vehicle details
  viewVehicles,

  // ==================== CUSTOMER PERMISSIONS ====================
  /// Manage own vehicles (add, edit, delete)
  manageOwnVehicles,

  /// Book service appointments
  bookAppointments,

  /// View own job cards (read-only)
  viewOwnJobCards,

  /// View own invoices
  viewOwnInvoices,

  /// Update own profile
  updateOwnProfile,

  // ==================== SHARED PERMISSIONS ====================
  /// View dashboard
  viewDashboard,

  /// View notifications
  viewNotifications,
}

/// Role-based permission mappings
class RolePermissions {
  /// Get all permissions for a given role
  static Set<Permission> getPermissionsForRole(
    String role, {
    bool isSuperAdmin = false,
  }) {
    switch (role.toLowerCase()) {
      case 'admin':
        return isSuperAdmin ? _superAdminPermissions : _adminPermissions;
      case 'mechanic':
        return _mechanicPermissions;
      case 'customer':
        return _customerPermissions;
      default:
        return {};
    }
  }

  /// Super Admin has all permissions including creating admins
  static final Set<Permission> _superAdminPermissions = {
    // All admin permissions
    ..._adminPermissions,
    // Plus super admin exclusive permissions
    Permission.createAdmins,
  };

  /// Admin has all permissions
  static final Set<Permission> _adminPermissions = {
    // Admin-specific
    Permission.manageUsers,
    Permission.manageSettings,
    Permission.viewReports,
    Permission.deleteData,
    Permission.manageInventory,
    Permission.createJobCards,
    Permission.deleteJobCards,
    Permission.viewAllCustomers,
    Permission.addCustomer,
    Permission.editCustomers,
    Permission.viewAllMechanics,
    Permission.editMechanics,

    // Mechanic permissions (admin can do everything mechanic can)
    Permission.viewJobCards,
    Permission.updateJobCards,
    Permission.addPartsToVehicles,
    Permission.viewCustomerDetails,
    Permission.viewInventory,
    Permission.viewVehicles,

    // Shared
    Permission.viewDashboard,
    Permission.viewNotifications,
  };

  /// Mechanic permissions - limited to job card management
  static final Set<Permission> _mechanicPermissions = {
    Permission.viewJobCards,
    Permission.updateJobCards,
    Permission.addPartsToVehicles,
    Permission.viewCustomerDetails,
    Permission.viewInventory,
    Permission.viewVehicles,
    Permission.viewDashboard,
    Permission.viewNotifications,
  };

  /// Customer permissions - self-service only
  static final Set<Permission> _customerPermissions = {
    Permission.manageOwnVehicles,
    Permission.bookAppointments,
    Permission.viewOwnJobCards,
    Permission.viewOwnInvoices,
    Permission.updateOwnProfile,
    Permission.viewDashboard,
    Permission.viewNotifications,
  };

  /// Check if a role has a specific permission
  static bool hasPermission(
    String role,
    Permission permission, {
    bool isSuperAdmin = false,
  }) {
    final permissions = getPermissionsForRole(role, isSuperAdmin: isSuperAdmin);
    return permissions.contains(permission);
  }

  /// Check if a role has any of the given permissions
  static bool hasAnyPermission(
    String role,
    List<Permission> permissions, {
    bool isSuperAdmin = false,
  }) {
    final rolePermissions = getPermissionsForRole(
      role,
      isSuperAdmin: isSuperAdmin,
    );
    return permissions.any((p) => rolePermissions.contains(p));
  }

  /// Check if a role has all of the given permissions
  static bool hasAllPermissions(
    String role,
    List<Permission> permissions, {
    bool isSuperAdmin = false,
  }) {
    final rolePermissions = getPermissionsForRole(
      role,
      isSuperAdmin: isSuperAdmin,
    );
    return permissions.every((p) => rolePermissions.contains(p));
  }
}
