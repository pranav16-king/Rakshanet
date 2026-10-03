import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, AlertCircle, ShieldAlert, ArrowLeft } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { Logo } from '../../components/common/Logo';
import heliRescueImg from '../../assets/helicopter-rescue.jpg';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { login, isLoading, error, clearError } = useAuthStore();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  // Retrieve previous redirect target if any
  const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/app/dashboard';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setLocalError(null);

    if (!email.trim() || !password.trim()) {
      setLocalError('Please enter both your command email and password.');
      return;
    }

    const success = await login(email, password, rememberMe);
    if (success) {
      navigate(from, { replace: true });
    }
  };

  const handleFillDemo = (adminEmail = 'admin@signalrescue.org', adminPass = 'SignalRescue@2026') => {
    setEmail(adminEmail);
    setPassword(adminPass);
    clearError();
    setLocalError(null);
  };

  return (
    <div className="h-screen w-full flex bg-[#F8FAFC] dark:bg-[#0B1220] text-[#16202D] dark:text-[#EEF2F8] selection:bg-[#FFC400] selection:text-[#1A1400] overflow-hidden">
      {/* Left Column: Sign In Form matching media_1791015140209.jpg */}
      <div className="w-full lg:w-1/2 flex flex-col justify-between px-6 py-4 sm:px-10 sm:py-5 lg:px-12 lg:py-6 h-full overflow-y-auto">
        {/* Top Header / Back Link */}
        <div className="flex items-center justify-between shrink-0">
          <button
            onClick={() => navigate('/')}
            className="flex items-center gap-1.5 text-xs font-bold text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white transition-colors cursor-pointer"
          >
            <ArrowLeft size={15} />
            <span>Back to SignalRescue AI</span>
          </button>
          <div className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-500/30 text-[10px] font-bold text-emerald-700 dark:text-emerald-400">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span>Gateway Ready</span>
          </div>
        </div>

        {/* Center Form Container (Compact & Perfectly Centered) */}
        <div className="max-w-sm w-full mx-auto my-auto py-2">
          {/* Logo & Headline */}
          <div className="flex flex-col items-center text-center mb-4">
            <Logo size="md" showSubtitle subtitle="Command Center" className="mb-2" />
            <p className="text-xs text-[#566070] dark:text-[#9FADC2]">
              Sign in to access the rescue command center.
            </p>
          </div>

          {/* Error Banner */}
          {(localError || error) && (
            <div className="mb-3 p-3 rounded-lg bg-[#FDE2DF] dark:bg-[#3A1512] border border-[#D92D20]/30 text-[#D92D20] dark:text-[#FF5A4E] text-xs font-semibold flex items-start gap-2">
              <AlertCircle size={16} className="flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <span>{localError || error}</span>
              </div>
            </div>
          )}

          {/* Quick Demo Access Bar */}
          <div className="mb-3.5 p-2.5 rounded-xl bg-[#FFF5C2] dark:bg-[#162036] border border-[#C9BB6E] dark:border-[#26344F] flex items-center justify-between shadow-xs">
            <div className="flex items-center gap-2 text-xs font-semibold text-[#8A5A00] dark:text-[#FFD21F]">
              <ShieldAlert size={15} className="shrink-0" />
              <span className="text-[11px] sm:text-xs">Incident Commander</span>
            </div>
            <button
              type="button"
              onClick={() => handleFillDemo('admin@signalrescue.org', 'SignalRescue@2026')}
              className="text-[11px] font-bold text-[#16202D] dark:text-white bg-white dark:bg-[#0B1220] px-2.5 py-1 rounded-md border border-[#E6DCA8] dark:border-[#3A4C70] hover:bg-[#FFEFA6] dark:hover:bg-[#111A2C] transition-colors cursor-pointer shadow-xs active:scale-95"
            >
              Fill Credentials
            </button>
          </div>

          {/* Sign In Form */}
          <form onSubmit={handleSubmit} className="space-y-3">
            {/* Email Field */}
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#16202D] dark:text-[#EEF2F8] mb-1">
                Email
              </label>
              <div className="relative">
                <Mail
                  size={16}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
                />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@signalrescue.org or your email"
                  required
                  className="w-full h-10 pl-9 pr-3 rounded-lg bg-white dark:bg-[#0E1627] border border-[#CBD5E1] dark:border-[#26344F] text-xs text-[#16202D] dark:text-[#EEF2F8] placeholder-[#94A3B8] dark:placeholder-[#64748B] focus:outline-none focus:ring-2 focus:ring-[#FFC400] dark:focus:ring-[#FFD21F] shadow-xs transition-all"
                />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#16202D] dark:text-[#EEF2F8] mb-1">
                Password
              </label>
              <div className="relative">
                <Lock
                  size={16}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
                />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  required
                  className="w-full h-10 pl-9 pr-9 rounded-lg bg-white dark:bg-[#0E1627] border border-[#CBD5E1] dark:border-[#26344F] text-xs text-[#16202D] dark:text-[#EEF2F8] placeholder-[#94A3B8] dark:placeholder-[#64748B] focus:outline-none focus:ring-2 focus:ring-[#FFC400] dark:focus:ring-[#FFD21F] shadow-xs transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white cursor-pointer"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between text-xs pt-0.5">
              <label className="flex items-center gap-1.5 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-3.5 h-3.5 rounded border-[#CBD5E1] dark:border-[#26344F] text-[#FFC400] focus:ring-[#FFC400] dark:bg-[#0E1627]"
                />
                <span className="font-semibold text-[11px] text-[#16202D] dark:text-[#EEF2F8]">
                  Remember me
                </span>
              </label>
              <button
                type="button"
                onClick={() => alert('Default credentials: admin@signalrescue.org / SignalRescue@2026')}
                className="font-medium text-[11px] text-[#8A5A00] dark:text-[#FFD21F] hover:underline cursor-pointer"
              >
                Forgot password?
              </button>
            </div>

            {/* Submit Button in Official Signal Yellow */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full h-10 mt-1 bg-[#FFC400] hover:bg-[#FFD21F] active:scale-[0.99] text-[#0B1220] font-black text-xs uppercase tracking-wider rounded-lg shadow-sm hover:shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {isLoading ? (
                <span className="w-4 h-4 border-2 border-[#0B1220] border-t-transparent rounded-full animate-spin" />
              ) : (
                <span>Sign In</span>
              )}
            </button>
          </form>

          {/* Need access text */}
          <div className="mt-4 text-center text-[11px] text-[#566070] dark:text-[#9FADC2]">
            <span>Need access? </span>
            <a
              href="mailto:support@rakshanet.gov.in"
              className="font-semibold text-[#16202D] dark:text-white hover:underline"
            >
              Contact your administrator.
            </a>
          </div>
        </div>

        {/* Footer info */}
        <div className="text-center text-[10px] text-[#566070] dark:text-[#9FADC2] shrink-0 pt-2">
          Authorized Emergency Response Personnel Only · Protected by DTN Cryptography
        </div>
      </div>

      {/* Right Column: Helicopter Rescue Hero matching media_1791015140209.jpg */}
      <div className="hidden lg:block lg:w-1/2 relative bg-[#0B1220] h-full overflow-hidden">
        {/* Background photo */}
        <img
          src={heliRescueImg}
          alt="Helicopter Rescue Operation"
          className="w-full h-full object-cover object-center filter brightness-95 contrast-105"
        />

        {/* Gradient overlay for readability */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#0B1220]/90 via-[#0B1220]/25 to-transparent" />

        {/* Big typography overlay matching screenshot */}
        <div className="absolute bottom-12 left-10 right-10 z-10 text-white">
          <h2
            className="text-4xl xl:text-5xl font-black tracking-tight leading-[1.05] mb-4 drop-shadow-lg"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Coordinate <br />
            Respond <br />
            Save Lives
          </h2>

          {/* Yellow accent line beneath */}
          <div className="w-16 h-1.5 bg-[#FFD21F] rounded-full shadow-lg shadow-yellow-500/50" />
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
