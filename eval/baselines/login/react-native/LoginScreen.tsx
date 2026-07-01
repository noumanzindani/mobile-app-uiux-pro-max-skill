// BASELINE — "no-skill" reference generation for the eval harness.
// Typical AI-emitted React Native login WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, physical left/right padding, an
// undersized touch target, sub-legible text, and only the happy path — none of
// the required UI states. Graded against the token-driven,
// all-states version in examples/login/react-native/.
//
// DO NOT copy this file. It exists only to measure the skill's lift.
import React from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';

export default function LoginScreen() {
  return (
    <View style={styles.screen}>
      <Text style={styles.title}>Login</Text>
      <TextInput placeholder="Email" style={styles.input} />
      <TextInput placeholder="Password" secureTextEntry style={styles.input} />
      <Text style={styles.forgot}>Forgot password?</Text>
      <TouchableOpacity style={styles.button} onPress={() => {}}>
        <Text style={styles.buttonText}>Sign in</Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={() => {}} style={{ width: 36, height: 36, marginTop: 12 }}>
        <Text>✕</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#FFFFFF', paddingLeft: 18, paddingRight: 18, paddingTop: 60 },
  title: { fontSize: 26, color: '#111827' },
  input: { height: 44, marginTop: 15, borderColor: '#E5E7EB', borderWidth: 1 },
  forgot: { fontSize: 10, color: '#3B82F6', marginTop: 6 },
  button: { height: 44, backgroundColor: '#3B82F6', alignItems: 'center', justifyContent: 'center', marginTop: 18 },
  buttonText: { color: '#FFFFFF' },
});
