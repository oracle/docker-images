// mobile-app/VacationRequestApp/screens/employee/VacationRequestFormScreen.js
import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, Alert } from 'react-native';
// Consider using a date picker library like @react-native-community/datetimepicker

const VacationRequestFormScreen = () => {
  const [startDate, setStartDate] = useState(new Date());
  const [endDate, setEndDate] = useState(new Date());
  const [reason, setReason] = useState('');

  const handleSubmit = () => {
    // TODO: Implement actual submission logic (call API)
    console.log('Submitting vacation request:', { startDate, endDate, reason });
    if (!reason) {
        Alert.alert('Error', 'Please provide a reason for your request.');
        return;
    }
    Alert.alert('Request Submitted (Placeholder)', `From: ${startDate.toDateString()}\nTo: ${endDate.toDateString()}\nReason: ${reason}`);
    // Clear form or navigate away
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>New Vacation Request</Text>
      {/* Placeholder for Date Pickers */}
      <Text>Start Date: (Date Picker Placeholder)</Text>
      <Text>End Date: (Date Picker Placeholder)</Text>
      <TextInput
        style={styles.input}
        placeholder="Reason for request"
        value={reason}
        onChangeText={setReason}
        multiline
      />
      <Button title="Submit Request" onPress={handleSubmit} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 22, marginBottom: 20, textAlign: 'center' },
  input: { height: 100, borderColor: 'gray', borderWidth: 1, marginBottom: 20, paddingHorizontal: 10, textAlignVertical: 'top' },
});

export default VacationRequestFormScreen;
