import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { TopBar } from './TopBar';
import { useWebSocket } from '../../hooks/useWebSocket';
import { EmergencyToastContainer } from '../common/EmergencyDispatchToast';

export const AppShell: React.FC = () => {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const { status: connectionStatus } = useWebSocket();

  return (
    <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#0B1220] text-[#0F172A] dark:text-[#EEF2F8] transition-colors duration-200">
      {/* High-Visibility Emergency Dispatch Toast Container */}
      <EmergencyToastContainer />

      {/* Sidebar Navigation */}
      <Sidebar
        isCollapsed={isCollapsed}
        onToggleCollapse={() => setIsCollapsed(!isCollapsed)}
        connectionStatus={connectionStatus}
      />

      {/* Top Application Bar */}
      <TopBar isSidebarCollapsed={isCollapsed} />

      {/* Main Content Area */}
      <main
        className={`pt-16 min-h-screen transition-all duration-300 ease-in-out ${
          isCollapsed ? 'ml-[72px]' : 'ml-[260px]'
        }`}
      >
        <div className="p-6 max-w-7xl mx-auto">
          <Outlet />
        </div>
      </main>
    </div>
  );
};

export default AppShell;
