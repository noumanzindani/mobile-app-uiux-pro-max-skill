// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, physical left/right padding, sub-legible
// captions, a fixed 2-column grid (no size classes), and only the happy path with
// none of the required UI states. Graded against examples/dashboard/react-native/.
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function DashboardScreen() {
  const tiles = ['Revenue', 'Orders', 'Visitors', 'Refunds'];
  return (
    <View style={styles.screen}>
      <Text style={styles.title}>Dashboard</Text>
      <View style={styles.grid}>
        {tiles.map((t, i) => (
          <View key={i} style={styles.tile}>
            <Text style={styles.tileTitle}>{t}</Text>
            <Text style={styles.delta}>+12%</Text>
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#F9FAFB', paddingLeft: 18, paddingRight: 18, paddingTop: 50 },
  title: { fontSize: 22, color: '#111827' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', marginTop: 14 },
  tile: { width: '50%', padding: 10, backgroundColor: '#FFFFFF' },
  tileTitle: { color: '#111827' },
  delta: { fontSize: 10, color: '#16A34A' },
});
