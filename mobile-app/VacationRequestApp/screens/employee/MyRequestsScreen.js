// mobile-app/VacationRequestApp/screens/employee/MyRequestsScreen.js
import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, StyleSheet, ActivityIndicator } from 'react-native';

const MyRequestsScreen = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  // TODO: Fetch actual requests from API in useEffect
  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setRequests([
        { id: '1', startDate: '2024-01-10', endDate: '2024-01-12', reason: 'Family event', status: 'Approved' },
        { id: '2', startDate: '2024-02-15', endDate: '2024-02-17', reason: 'Personal time', status: 'Pending' },
        { id: '3', startDate: '2023-12-20', endDate: '2023-12-22', reason: 'Holiday', status: 'Rejected' },
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  if (loading) {
    return <ActivityIndicator size="large" style={styles.loader} />;
  }

  if (requests.length === 0) {
    return <View style={styles.container}><Text>No vacation requests found.</Text></View>;
  }

  return (
    <FlatList
      data={requests}
      keyExtractor={item => item.id}
      renderItem={({ item }) => (
        <View style={styles.requestItem}>
          <Text style={styles.reason}>{item.reason}</Text>
          <Text>From: {item.startDate} To: {item.endDate}</Text>
          <Text style={[styles.status, styles[`status${item.status}`]]}>Status: {item.status}</Text>
        </View>
      )}
      style={styles.container}
    />
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 10 },
  loader: { flex: 1, justifyContent: 'center', alignItems: 'center'},
  requestItem: { padding: 15, marginVertical: 5, backgroundColor: '#f9f9f9', borderColor: '#eee', borderWidth: 1, borderRadius: 5 },
  reason: { fontSize: 16, fontWeight: 'bold' },
  status: { marginTop: 5, fontWeight: 'bold' },
  statusApproved: { color: 'green' },
  statusPending: { color: 'orange' },
  statusRejected: { color: 'red' },
});

export default MyRequestsScreen;
