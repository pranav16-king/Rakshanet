import React, { useEffect } from 'react';
import { Navigate, useLocation, Outlet } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';

export const ProtectedRoute: React.FC = () => {
  const { isAuthenticated, isInitializing, checkAuth } = useAuthStore();
  const location = useLocation();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  if (isInitializing) {
    return (
      <div className="min-h-screen bg-[#0B1220] flex flex-col items-center justify-center p-6 text-center select-none">
        <div className="relative mb-6">
          <div className="w-16 h-16 rounded-2xl bg-[#FFD21F] flex items-center justify-center shadow-xl shadow-yellow-500/20 animate-pulse">
            <svg viewBox="0 0 24 24" fill="none" className="w-10 h-10">
              <path d="M12 3L2 20h20L12 3z" fill="#0B1220" />
              <path d="M12 8v5" stroke="#FFD21F" strokeWidth="2.5" strokeLinecap="round" />
              <circle cx="12" cy="16.5" r="1.2" fill="#FFD21F" />
            </svg>
          </div>
          <span className="animate-ping absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[#FFD21F] opacity-75" />
        </div>
        <h3
          className="text-lg font-bold text-white tracking-wide mb-2"
          style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
        >
          Connecting to RakshaNet Command Grid...
        </h3>
        <p className="text-xs text-[#9FADC2]">
          Verifying security clearance and cryptographic DTN mesh credentials
        </p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/auth/login" state={{ from: location }} replace />;
  }

  return <Outlet />;
};

export default ProtectedRoute;
