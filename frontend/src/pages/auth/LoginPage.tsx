import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, AlertCircle, ShieldAlert } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { Logo } from '../../components/common/Logo';
import { Button } from '../../components/common/Button';
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

  const handleFillDemo = () => {
    setEmail('admin@rakshanet.gov.in');
    setPassword('DisasterResponse@2026');
    clearError();
    setLocalError(null);
  };

  return (
    <div className="min-h-screen w-full flex bg-white dark:bg-[#0B1220] text-[#16202D] dark:text-[#EEF2F8] selection:bg-[#FFC400] selection:text-[#1A1400]">
      {/* Left Column: Sign In Form matching media_1791015140209.jpg */}
      <div className="w-full lg:w-1/2 flex flex-col justify-between p-8 sm:p-12 lg:p-16 overflow-y-auto">
        {/* Top Header / Back Link */}
        <div className="flex items-center justify-between">
          <button
            onClick={() => navigate('/')}
            className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white transition-colors cursor-pointer"
          >
            ← Back to SignalRescue AI
          </button>
          <div className="flex items-center gap-2 px-2.5 py-1 rounded-full bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-500/30 text-[11px] font-bold text-emerald-700 dark:text-emerald-400">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Gateway Ready</span>
          </div>
        </div>

        {/* Center Form Container */}
        <div className="max-w-md w-full mx-auto my-8">
          {/* Logo & Headline */}
          <div className="flex flex-col items-center text-center mb-8">
            <Logo size="lg" showSubtitle subtitle="Command Center" className="mb-4" />
            <p className="text-sm text-[#566070] dark:text-[#9FADC2]">
              Sign in to access the rescue command center.
            </p>
          </div>

          {/* Error Banner */}
          {(localError || error) && (
            <div className="mb-6 p-4 rounded-xl bg-[#FDE2DF] dark:bg-[#3A1512] border border-[#D92D20]/30 text-[#D92D20] dark:text-[#FF5A4E] text-xs font-semibold flex items-start gap-3 animate-shake">
              <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <span>{localError || error}</span>
              </div>
            </div>
          )}

          {/* Quick Demo Access Bar */}
          <div className="mb-6 p-3 rounded-xl bg-[#FFF5C2] dark:bg-[#162036] border border-[#C9BB6E] dark:border-[#26344F] flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-medium text-[#8A5A00] dark:text-[#FFD21F]">
              <ShieldAlert size={16} />
              <span>Demo Incident Commander</span>
            </div>
            <button
              type="button"
              onClick={handleFillDemo}
              className="text-xs font-bold text-[#16202D] dark:text-white bg-white dark:bg-[#0B1220] px-3 py-1 rounded-lg border border-[#E6DCA8] dark:border-[#3A4C70] hover:bg-[#FFEFA6] dark:hover:bg-[#111A2C] transition-colors cursor-pointer"
            >
              Fill Demo Login
            </button>
          </div>

          {/* Sign In Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#16202D] dark:text-[#EEF2F8] mb-2">
                Email
              </label>
              <div className="relative">
                <Mail
                  size={18}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
                />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your email"
                  required
                  className="w-full h-12 pl-11 pr-4 rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-sm text-[#16202D] dark:text-[#EEF2F8] placeholder-[#566070]/60 dark:placeholder-[#9FADC2]/60 focus:outline-none focus:ring-2 focus:ring-[#FFC400] dark:focus:ring-[#FFD21F] transition-all"
                />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#16202D] dark:text-[#EEF2F8] mb-2">
                Password
              </label>
              <div className="relative">
                <Lock
                  size={18}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
                />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  required
                  className="w-full h-12 pl-11 pr-11 rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-sm text-[#16202D] dark:text-[#EEF2F8] placeholder-[#566070]/60 dark:placeholder-[#9FADC2]/60 focus:outline-none focus:ring-2 focus:ring-[#FFC400] dark:focus:ring-[#FFD21F] transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white cursor-pointer"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between text-xs">
              <label className="flex items-center gap-2 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-[#E6DCA8] dark:border-[#26344F] text-[#FFC400] focus:ring-[#FFC400] dark:bg-[#0E1627]"
                />
                <span className="font-semibold text-[#16202D] dark:text-[#EEF2F8]">
                  Remember me
                </span>
              </label>
              <button
                type="button"
                onClick={() => alert('Please contact your district disaster management admin for password reset.')}
                className="font-medium text-[#8A5A00] dark:text-[#FFD21F] hover:underline cursor-pointer"
              >
                Forgot password?
              </button>
            </div>

            {/* Submit Button */}
            <Button
              type="submit"
              variant="secondary"
              size="lg"
              isLoading={isLoading}
              className="w-full h-12 bg-[#0B1220] hover:bg-[#162036] text-white dark:bg-[#FFD21F] dark:hover:bg-[#FFC400] dark:text-[#0B1220] font-bold text-sm tracking-wide rounded-xl shadow-lg transition-all"
            >
              Sign In
            </Button>
          </form>

          {/* Need access text */}
          <div className="mt-8 text-center text-xs text-[#566070] dark:text-[#9FADC2]">
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
        <div className="text-center text-[11px] text-[#566070] dark:text-[#9FADC2]">
          Authorized Emergency Response Personnel Only · Protected by DTN Cryptography
        </div>
      </div>

      {/* Right Column: Helicopter Rescue Hero matching media_1791015140209.jpg */}
      <div className="hidden lg:block lg:w-1/2 relative bg-[#0B1220] overflow-hidden">
        {/* Background photo */}
        <img
          src={heliRescueImg}
          alt="Helicopter Rescue Operation"
          className="w-full h-full object-cover object-center filter brightness-90 contrast-105"
        />

        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#0B1220] via-transparent to-[#0B1220]/40" />

        {/* Big typography overlay matching screenshot */}
        <div className="absolute bottom-20 left-16 right-16 z-10 text-white">
          <h2
            className="text-5xl font-black tracking-tight leading-[1.1] mb-6"
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
