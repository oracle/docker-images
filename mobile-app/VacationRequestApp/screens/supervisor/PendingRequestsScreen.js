// mobile-app/VacationRequestApp/screens/supervisor/PendingRequestsScreen.js
import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, Button, StyleSheet, ActivityIndicator, TouchableOpacity } from 'react-native';

const PendingRequestsScreen = ({ navigation }) => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  // TODO: Fetch actual pending requests for this supervisor from API
  useEffect(() => {
    setTimeout(() => {
      setRequests([
        { id: '101', employeeName: 'John Doe', userId: 'emp001', startDate: '2024-03-10', endDate: '2024-03-12', reason: 'Conference', status: 'Pending' },
        { id: '102', employeeName: 'Jane Smith', userId: 'emp002', startDate: '2024-03-15', endDate: '2024-03-17', reason: 'Personal Appointment', status: 'Pending' },
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  const handleViewDetails = (request) => {
    navigation.navigate('RequestDetailScreen', { request });
  };

  if (loading) {
    return <ActivityIndicator size="large" style={styles.loader} />;
  }

  if (requests.length === 0) {
    return <View style={styles.container}><Text>No pending vacation requests.</Text></View>;
  }

  return (
    <FlatList
      data={requests}
      keyExtractor={item => item.id}
      renderItem={({ item }) => (
        <TouchableOpacity onPress={() => handleViewDetails(item)} style={styles.requestItem}>
          <Text style={styles.employeeName}>{item.employeeName}</Text>
          <Text>Dates: {item.startDate} to {item.endDate}</Text>
          <Text>Reason: {item.reason}</Text>
          <View style={styles.buttonContainer}>
             {/* Button removed as the whole item is touchable */}
          </View>
        </TouchableOpacity>
      )}
      style={styles.container}
    />
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 10 },
  loader: { flex: 1, justifyContent: 'center', alignItems: 'center'},
  requestItem: { padding: 15, marginVertical: 8, backgroundColor: '#fff', borderColor: '#ddd', borderWidth: 1, borderRadius: 8 },
  employeeName: { fontSize: 16, fontWeight: 'bold' },
  buttonContainer: { marginTop: 10 }
});

export default PendingRequestsScreen;
