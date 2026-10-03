import React from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar.tsx';
import { Header } from './Header.tsx';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface CommandCenterLayoutProps {
  children?: React.ReactNode;
}

export const CommandCenterLayout: React.FC<CommandCenterLayoutProps> = ({ children }) => {
  const { theme, isDark } = useTheme();
  const [isCollapsed, setIsCollapsed] = React.useState(false);

  return (
    <div
      className={`min-h-screen flex font-body transition-colors ${
        theme === 'oled'
          ? 'bg-black text-[#EEF2F8]'
          : isDark
          ? 'bg-[#0B1220] text-[#EEF2F8]'
          : 'bg-[#FFFCEB] text-[#16202D]'
      }`}
    >
      {/* Navigation Sidebar */}
      <Sidebar isCollapsed={isCollapsed} onToggleCollapse={() => setIsCollapsed(!isCollapsed)} />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <Header />
        <main className="flex-1 overflow-y-auto">
          {children || <Outlet />}
        </main>
      </div>
    </div>
  );
};
