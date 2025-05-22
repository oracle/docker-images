// mobile-app/VacationRequestApp/screens/supervisor/RequestDetailScreen.js
import React, {useState} from 'react';
import { View, Text, Button, StyleSheet, Alert, TextInput } from 'react-native';

const RequestDetailScreen = ({ route, navigation }) => {
  const { request } = route.params;
  const [supervisorComments, setSupervisorComments] = useState('');

  const handleApprove = () => {
    // TODO: Implement actual approve logic (call API)
    console.log('Approving request:', request.id, 'with comments:', supervisorComments);
    Alert.alert('Request Approved (Placeholder)', `Request ID: ${request.id} has been approved.`);
    navigation.goBack();
  };

  const handleReject = () => {
    // TODO: Implement actual reject logic (call API)
    if (!supervisorComments) {
        Alert.alert('Comment Required', 'Please provide a comment when rejecting a request.');
        return;
    }
    console.log('Rejecting request:', request.id, 'with comments:', supervisorComments);
    Alert.alert('Request Rejected (Placeholder)', `Request ID: ${request.id} has been rejected.`);
    navigation.goBack();
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Request Details</Text>
      <Text>Employee: {request.employeeName}</Text>
      <Text>User ID: {request.userId}</Text>
      <Text>Start Date: {request.startDate}</Text>
      <Text>End Date: {request.endDate}</Text>
      <Text>Reason: {request.reason}</Text>
      <Text style={styles.status}>Status: {request.status}</Text>
      
      <TextInput
        style={styles.input}
        placeholder="Supervisor Comments (required if rejecting)"
        value={supervisorComments}
        onChangeText={setSupervisorComments}
        multiline
      />

      <View style={styles.buttonRow}>
        <Button title="Approve" onPress={handleApprove} color="green" />
        <Button title="Reject" onPress={handleReject} color="red" />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 22, fontWeight: 'bold', marginBottom: 15 },
  status: { marginVertical: 10, fontWeight: 'bold' },
  input: { 
    height: 100, 
    borderColor: 'gray', 
    borderWidth: 1, 
    marginBottom: 20, 
    marginTop: 10,
    paddingHorizontal: 10, 
    textAlignVertical: 'top' 
  },
  buttonRow: { flexDirection: 'row', justifyContent: 'space-around', marginTop: 20 },
});

export default RequestDetailScreen;
