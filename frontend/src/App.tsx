import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './theme/ThemeContext';
import { AppShell } from './components/layout/AppShell';
import { ProtectedRoute } from './components/layout/ProtectedRoute';

// Public Pages
import { LandingPage } from './pages/LandingPage';
import { LoginPage } from './pages/auth/LoginPage';

// Command Center Multi-Page Application
import { DashboardPage } from './pages/dashboard/DashboardPage';
import { OverviewPage } from './pages/overview/OverviewPage';
import { LiveMapPage } from './pages/map/LiveMapPage';
import { IncidentsPage } from './pages/incidents/IncidentsPage';
import { IncidentsListPage } from './pages/incidents/IncidentsListPage';
import { IncidentDetailPage } from './pages/incidents/IncidentDetailPage';
import { RescueOpsPage } from './pages/rescue-ops/RescueOpsPage';
import { CommunicationGapsPage } from './pages/communication-gaps/CommunicationGapsPage';
import { PeoplePage } from './pages/people/PeoplePage';
import { MessagesPage } from './pages/messages/MessagesPage';
import { DevicesPage } from './pages/devices/DevicesPage';
import { ResourcesPage } from './pages/resources/ResourcesPage';
import { AnalyticsPage } from './pages/analytics/AnalyticsPage';
import { ReportsPage } from './pages/reports/ReportsPage';
import { SettingsPage } from './pages/settings/SettingsPage';
import { MissingPersonsPage } from './pages/missing-persons/MissingPersonsPage';
import { MeshArchitecturePage } from './pages/architecture/MeshArchitecturePage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5000,
    },
  },
});

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <BrowserRouter>
          <Routes>
            {/* Public Routes */}
            <Route path="/" element={<LandingPage />} />
            <Route path="/auth/login" element={<LoginPage />} />
            <Route path="/mesh-architecture" element={<MeshArchitecturePage />} />

            {/* Protected Command Center Platform (Strict JWT Authentication Gate) */}
            <Route element={<ProtectedRoute />}>
              <Route path="/app" element={<AppShell />}>
                <Route index element={<Navigate to="/app/dashboard" replace />} />
                <Route path="dashboard" element={<DashboardPage />} />
                <Route path="overview" element={<OverviewPage />} />
                <Route path="map" element={<LiveMapPage />} />
                <Route path="incidents" element={<IncidentsPage />} />
                <Route path="incidents/list" element={<IncidentsListPage />} />
                <Route path="incidents/:id" element={<IncidentDetailPage />} />
                <Route path="rescue-ops" element={<RescueOpsPage />} />
                <Route path="communication-gaps" element={<CommunicationGapsPage />} />
                <Route path="people" element={<PeoplePage />} />
                <Route path="missing-persons" element={<MissingPersonsPage />} />
                <Route path="messages" element={<MessagesPage />} />
                <Route path="devices" element={<DevicesPage />} />
                <Route path="resources" element={<ResourcesPage />} />
                <Route path="analytics" element={<AnalyticsPage />} />
                <Route path="reports" element={<ReportsPage />} />
                <Route path="settings" element={<SettingsPage />} />
                <Route path="mesh-architecture" element={<MeshArchitecturePage />} />
                <Route path="*" element={<Navigate to="/app/dashboard" replace />} />
              </Route>
            </Route>

            {/* Global Fallback */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
