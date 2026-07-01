// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, physical left/right padding, a
// destructive action inline with the rest (not isolated), sub-legible captions,
// and only the happy path with none of the required UI states. Graded against
// examples/settings/react-native/.
import React, { useState } from 'react';
import { View, Text, Switch, TouchableOpacity, StyleSheet } from 'react-native';

export default function SettingsScreen() {
  const [notifications, setNotifications] = useState(true);
  const [darkTheme, setDarkTheme] = useState(false);
  return (
    <View style={styles.screen}>
      <Text style={styles.title}>Settings</Text>
      <View style={styles.row}>
        <Text>Notifications</Text>
        <Switch value={notifications} onValueChange={setNotifications} />
      </View>
      <View style={styles.row}>
        <Text>Dark theme</Text>
        <Switch value={darkTheme} onValueChange={setDarkTheme} />
      </View>
      <Text style={styles.caption}>Signed in as user@example.com</Text>
      <TouchableOpacity onPress={() => {}}>
        <Text style={styles.delete}>Delete account</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#FFFFFF', paddingLeft: 18, paddingRight: 18, paddingTop: 50 },
  title: { fontSize: 22, color: '#111827' },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 15 },
  caption: { fontSize: 10, color: '#6B7280', marginTop: 15 },
  delete: { color: '#DC2626', marginTop: 10 },
});
