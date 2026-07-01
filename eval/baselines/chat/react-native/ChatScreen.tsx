// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, physical left/right padding, an
// undersized send button, sub-legible timestamps, and only the happy path with
// none of the required UI states. Graded against examples/chat/react-native/.
import React from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, StyleSheet } from 'react-native';

export default function ChatScreen() {
  const messages = ['Hey!', 'How are you?', 'On my way'];
  return (
    <View style={styles.screen}>
      <ScrollView contentContainerStyle={styles.list}>
        {messages.map((m, i) => (
          <View key={i} style={styles.bubble}>
            <Text style={styles.bubbleText}>{m}</Text>
          </View>
        ))}
        <Text style={styles.time}>12:04</Text>
      </ScrollView>
      <View style={styles.composer}>
        <TextInput placeholder="Message" style={styles.input} />
        <TouchableOpacity onPress={() => {}} style={{ width: 36, height: 36 }}>
          <Text>➤</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#F3F4F6' },
  list: { paddingLeft: 18, paddingRight: 18, paddingTop: 10 },
  bubble: { backgroundColor: '#2563EB', margin: 6, padding: 10 },
  bubbleText: { color: '#FFFFFF' },
  time: { fontSize: 10, color: '#6B7280' },
  composer: { flexDirection: 'row', alignItems: 'center', padding: 10 },
  input: { flex: 1, height: 44, borderColor: '#E5E7EB', borderWidth: 1 },
});
