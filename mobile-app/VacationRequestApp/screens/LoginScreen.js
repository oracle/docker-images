// mobile-app/VacationRequestApp/screens/LoginScreen.js
import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, Alert } from 'react-native';

const LoginScreen = ({ navigation }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = () => {
    // TODO: Implement actual login logic (call API)
    console.log('Login attempt with:', email, password);
    if (email === '' || password === '') {
        Alert.alert('Error', 'Please enter email and password');
        return;
    }
    
    // Navigate to employee home or supervisor home based on role after successful login
    if (email.toLowerCase().startsWith('sup')) {
      Alert.alert('Login Success (Placeholder)', 'Navigating to Supervisor Dashboard...');
      navigation.replace('SupervisorWorkflow'); // Use replace to avoid back to login
    } else {
      Alert.alert('Login Success (Placeholder)', 'Navigating to Employee Dashboard...');
      navigation.replace('EmployeeTabs'); // Use replace
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Login</Text>
      <TextInput
        style={styles.input}
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        autoCapitalize="none"
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />
      <Button title="Login" onPress={handleLogin} />
      {/* TODO: Add signup navigation if applicable */}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', padding: 20 },
  title: { fontSize: 24, marginBottom: 20, textAlign: 'center' },
  input: { height: 40, borderColor: 'gray', borderWidth: 1, marginBottom: 10, paddingHorizontal: 10 },
});

export default LoginScreen;
