// BASELINE — "no-skill" reference generation for the eval harness.
// Typical AI-emitted checkout WITHOUT the Mobile UI/UX Pro Max skill: hardcoded
// hex colors, off-grid spacing, physical left/right padding, a sub-legible price,
// an undersized quantity stepper, and none of the required UI states to
// prevent a double-charge. Graded against examples/checkout/react-native/.
//
// DO NOT copy this file. It exists only to measure the skill's lift.
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

export default function CheckoutScreen() {
  return (
    <View style={styles.screen}>
      <Text style={styles.title}>Checkout</Text>
      <View style={styles.row}>
        <Text>Wireless Headphones</Text>
        <Text style={styles.price}>$129.00</Text>
      </View>
      <View style={styles.stepper}>
        <TouchableOpacity onPress={() => {}} style={{ width: 32, height: 32 }}>
          <Text>-</Text>
        </TouchableOpacity>
        <Text style={styles.qty}>1</Text>
        <TouchableOpacity onPress={() => {}} style={{ width: 32, height: 32 }}>
          <Text>+</Text>
        </TouchableOpacity>
      </View>
      <Text style={styles.note}>Tax and shipping calculated at charge</Text>
      <TouchableOpacity style={styles.pay} onPress={() => {}}>
        <Text style={styles.payText}>Pay now</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#F9FAFB', paddingLeft: 18, paddingRight: 18, paddingTop: 50 },
  title: { fontSize: 22, color: '#111827' },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 14 },
  price: { fontSize: 10, color: '#111827' },
  stepper: { flexDirection: 'row', alignItems: 'center', marginTop: 14 },
  qty: { paddingLeft: 10, paddingRight: 10 },
  note: { fontSize: 10, color: '#9CA3AF', marginTop: 6 },
  pay: { height: 44, backgroundColor: '#16A34A', alignItems: 'center', justifyContent: 'center', marginTop: 22 },
  payText: { color: '#FFFFFF' },
});
