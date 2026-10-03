import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './theme/ThemeContext.tsx';
import { CommandCenterLayout } from './components/layout/CommandCenterLayout.tsx';
import { IncidentsListPage } from './pages/incidents/IncidentsListPage.tsx';
import { IncidentDetailPage } from './pages/incidents/IncidentDetailPage.tsx';

function App() {
  return (
    <ThemeProvider>
      <BrowserRouter>
        <Routes>
          {/* Main Command Center Application Layout */}
          <Route path="/app" element={<CommandCenterLayout />}>
            <Route index element={<Navigate to="/app/incidents" replace />} />
            <Route path="incidents" element={<IncidentsListPage />} />
            <Route path="incidents/:id" element={<IncidentDetailPage />} />

            {/* Quick Redirects for standard Command Center navigation items */}
            <Route
              path="dashboard"
              element={<Navigate to="/app/incidents" replace />}
            />
            <Route
              path="map"
              element={<Navigate to="/app/incidents/INC-2025-001" replace />}
            />
            <Route
              path="people"
              element={<Navigate to="/app/incidents/INC-2025-001" replace />}
            />
            <Route
              path="messages"
              element={<Navigate to="/app/incidents/INC-2025-001" replace />}
            />
            <Route
              path="devices"
              element={<Navigate to="/app/incidents/INC-2025-001" replace />}
            />
            <Route
              path="resources"
              element={<Navigate to="/app/incidents/INC-2025-001" replace />}
            />
            <Route
              path="*"
              element={<Navigate to="/app/incidents" replace />}
            />
          </Route>

          {/* Root redirect */}
          <Route path="/" element={<Navigate to="/app/incidents" replace />} />
          <Route path="*" element={<Navigate to="/app/incidents" replace />} />
        </Routes>
      </BrowserRouter>
    </ThemeProvider>
  );
}

export default App;
