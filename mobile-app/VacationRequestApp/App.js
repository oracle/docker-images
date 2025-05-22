// mobile-app/VacationRequestApp/App.js
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

import LoginScreen from './screens/LoginScreen';
import VacationRequestFormScreen from './screens/employee/VacationRequestFormScreen';
import MyRequestsScreen from './screens/employee/MyRequestsScreen';

import PendingRequestsScreen from './screens/supervisor/PendingRequestsScreen';
import RequestDetailScreen from './screens/supervisor/RequestDetailScreen';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

// Employee Tab Navigator
function EmployeeTabs() {
  return (
    <Tab.Navigator>
      <Tab.Screen name="My Requests" component={MyRequestsScreen} />
      <Tab.Screen name="New Request" component={VacationRequestFormScreen} />
    </Tab.Navigator>
  );
}

// Supervisor Workflow Stack Navigator
const SupervisorStack = createStackNavigator();

function SupervisorWorkflowStack() {
  return (
    <SupervisorStack.Navigator>
      <SupervisorStack.Screen name="PendingRequests" component={PendingRequestsScreen} options={{ title: 'Pending Vacation Requests' }} />
      <SupervisorStack.Screen name="RequestDetailScreen" component={RequestDetailScreen} options={{ title: 'Request Details' }} />
    </SupervisorStack.Navigator>
  );
}

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login">
        <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
        <Stack.Screen name="EmployeeTabs" component={EmployeeTabs} options={{ title: 'Employee Dashboard' }}/>
        <Stack.Screen name="SupervisorWorkflow" component={SupervisorWorkflowStack} options={{ headerShown: false }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
