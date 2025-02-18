ListTile(
  leading: const Icon(Icons.verified_user),
  title: const Text('Verifikacija'),
  onTap: () {
    context.pushNamed('verification');
    if (onMenuItemSelected != null) {
      onMenuItemSelected!();
    }
  },
), 